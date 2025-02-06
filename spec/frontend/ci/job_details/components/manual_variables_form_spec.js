import { GlSprintf, GlLink } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { createAlert } from '~/alert';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TYPENAME_CI_BUILD } from '~/graphql_shared/constants';
import { JOB_GRAPHQL_ERRORS } from '~/ci/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import waitForPromises from 'helpers/wait_for_promises';
import { visitUrl } from '~/lib/utils/url_utility';
import ManualVariablesForm from '~/ci/job_details/components/manual_variables_form.vue';
import getJobQuery from '~/ci/job_details/graphql/queries/get_job.query.graphql';
import playJobMutation from '~/ci/job_details/graphql/mutations/job_play_with_variables.mutation.graphql';
import retryJobMutation from '~/ci/job_details/graphql/mutations/job_retry_with_variables.mutation.graphql';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';

import {
  mockFullPath,
  mockId,
  mockJobResponse,
  mockJobWithVariablesResponse,
  mockJobPlayMutationData,
  mockJobRetryMutationData,
} from '../mock_data';

jest.mock('~/lib/utils/confirm_via_gl_modal/confirm_action');
jest.mock('~/alert');
Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const defaultProvide = {
  projectPath: mockFullPath,
};

describe('Manual Variables Form', () => {
  let wrapper;
  let mockApollo;
  let requestHandlers;

  const getJobQueryResponseHandlerWithVariables = jest.fn().mockResolvedValue(mockJobResponse);
  const playJobMutationHandler = jest.fn().mockResolvedValue({});
  const retryJobMutationHandler = jest.fn().mockResolvedValue({});

  const defaultHandlers = {
    getJobQueryResponseHandlerWithVariables,
    playJobMutationHandler,
    retryJobMutationHandler,
  };

  const createComponent = ({ props = {}, handlers = defaultHandlers } = {}) => {
    requestHandlers = handlers;

    mockApollo = createMockApollo([
      [getJobQuery, handlers.getJobQueryResponseHandlerWithVariables],
      [playJobMutation, handlers.playJobMutationHandler],
      [retryJobMutation, handlers.retryJobMutationHandler],
    ]);

    const options = {
      apolloProvider: mockApollo,
    };

    wrapper = mountExtended(ManualVariablesForm, {
      propsData: {
        jobId: mockId,
        jobName: 'job-name',
        isRetryable: false,
        ...props,
      },
      provide: {
        ...defaultProvide,
      },
      ...options,
    });

    return waitForPromises();
  };

  const findHelpText = () => wrapper.findComponent(GlSprintf);
  const findHelpLink = () => wrapper.findComponent(GlLink);
  const findCancelBtn = () => wrapper.findByTestId('cancel-btn');
  const findRunBtn = () => wrapper.findByTestId('run-manual-job-btn');
  const findDeleteVarBtn = () => wrapper.findByTestId('delete-variable-btn');
  const findAllDeleteVarBtns = () => wrapper.findAllByTestId('delete-variable-btn');
  const findDeleteVarBtnPlaceholder = () => wrapper.findByTestId('delete-variable-btn-placeholder');
  const findCiVariableKey = () => wrapper.findByTestId('ci-variable-key');
  const findAllCiVariableKeys = () => wrapper.findAllByTestId('ci-variable-key');
  const findCiVariableValue = () => wrapper.findByTestId('ci-variable-value');
  const findAllVariables = () => wrapper.findAllByTestId('ci-variable-row');

  const setCiVariableKey = () => {
    findCiVariableKey().setValue('new key');
    findCiVariableKey().vm.$emit('change');
    nextTick();
  };

  const setCiVariableKeyByPosition = (position, value) => {
    findAllCiVariableKeys().at(position).setValue(value);
    findAllCiVariableKeys().at(position).vm.$emit('change');
    nextTick();
  };

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('when page renders', () => {
    beforeEach(async () => {
      await createComponent();
    });

    it('renders help text with provided link', () => {
      expect(findHelpText().exists()).toBe(true);
      expect(findHelpLink().attributes('href')).toBe('/help/ci/variables/_index#for-a-project');
    });
  });

  describe('when query is unsuccessful', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest.fn().mockRejectedValue({}),
        },
      });
    });

    it('shows an alert with error', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: JOB_GRAPHQL_ERRORS.jobQueryErrorText,
      });
    });
  });

  describe('when job has not been retried', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest
            .fn()
            .mockResolvedValue(mockJobWithVariablesResponse),
        },
      });
    });

    it('does not render the cancel button', () => {
      expect(findCancelBtn().exists()).toBe(false);
      expect(findRunBtn().exists()).toBe(true);
    });
  });

  describe('when job has variables', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest
            .fn()
            .mockResolvedValue(mockJobWithVariablesResponse),
        },
      });
    });

    it('sets manual job variables', () => {
      const queryKey = mockJobWithVariablesResponse.data.project.job.manualVariables.nodes[0].key;
      const queryValue =
        mockJobWithVariablesResponse.data.project.job.manualVariables.nodes[0].value;

      expect(findCiVariableKey().element.value).toBe(queryKey);
      expect(findCiVariableValue().element.value).toBe(queryValue);
    });
  });

  describe('when play mutation fires', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest
            .fn()
            .mockResolvedValue(mockJobWithVariablesResponse),
          playJobMutationHandler: jest.fn().mockResolvedValue(mockJobPlayMutationData),
        },
      });
    });

    it('passes variables in correct format', async () => {
      await setCiVariableKey();

      await findCiVariableValue().setValue('new value');

      await findRunBtn().vm.$emit('click');

      expect(requestHandlers.playJobMutationHandler).toHaveBeenCalledTimes(1);
      expect(requestHandlers.playJobMutationHandler).toHaveBeenCalledWith({
        id: convertToGraphQLId(TYPENAME_CI_BUILD, mockId),
        variables: [
          {
            key: 'new key',
            value: 'new value',
          },
        ],
      });
    });

    it('redirects to job properly after job is run', async () => {
      findRunBtn().vm.$emit('click');
      await waitForPromises();

      expect(requestHandlers.playJobMutationHandler).toHaveBeenCalledTimes(1);
      expect(visitUrl).toHaveBeenCalledWith(mockJobPlayMutationData.data.jobPlay.job.webPath);
    });

    it('does not refetch variables after job is run', async () => {
      expect(requestHandlers.getJobQueryResponseHandlerWithVariables).toHaveBeenCalledTimes(1);

      findRunBtn().vm.$emit('click');
      await waitForPromises();

      expect(requestHandlers.getJobQueryResponseHandlerWithVariables).toHaveBeenCalledTimes(1);
    });
  });

  describe('when play mutation is unsuccessful', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          playJobMutationHandler: jest.fn().mockRejectedValue({}),
        },
      });
    });

    it('shows an alert with error', async () => {
      findRunBtn().vm.$emit('click');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: JOB_GRAPHQL_ERRORS.jobMutationErrorText,
      });
    });
  });

  describe('when job is retryable', () => {
    beforeEach(async () => {
      await createComponent({
        props: { isRetryable: true },
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest
            .fn()
            .mockResolvedValue(mockJobWithVariablesResponse),
          retryJobMutationHandler: jest.fn().mockResolvedValue(mockJobRetryMutationData),
        },
      });
    });

    it('renders cancel button', () => {
      expect(findCancelBtn().exists()).toBe(true);
    });

    it('not render confirmation modal if confirmation message is null', async () => {
      findRunBtn().vm.$emit('click');
      await waitForPromises();

      expect(confirmAction).not.toHaveBeenCalled();
    });

    describe('with confirmation message', () => {
      beforeEach(async () => {
        await createComponent({
          props: {
            isRetryable: true,
            confirmationMessage: 'Are you sure?',
          },
          handlers: {
            getJobQueryResponseHandlerWithVariables: jest
              .fn()
              .mockResolvedValue(mockJobWithVariablesResponse),
            retryJobMutationHandler: jest.fn().mockResolvedValue(mockJobRetryMutationData),
          },
        });
      });

      it('render confirmation modal after click run button', async () => {
        findRunBtn().vm.$emit('click');
        await nextTick();
        await waitForPromises();

        expect(confirmAction).toHaveBeenCalledWith(
          null,
          expect.objectContaining({
            primaryBtnText: `Yes, run job-name`,
            title: `Are you sure you want to run job-name?`,
            modalHtmlMessage: expect.stringContaining('Are you sure?'),
          }),
        );
      });

      it('redirect to job properly after confirmation', async () => {
        confirmAction.mockResolvedValueOnce(true);
        findRunBtn().vm.$emit('click');
        await waitForPromises();

        expect(requestHandlers.retryJobMutationHandler).toHaveBeenCalledTimes(1);
        expect(visitUrl).toHaveBeenCalledWith(mockJobRetryMutationData.data.jobRetry.job.webPath);
      });
    });

    it('redirects to job properly after rerun', async () => {
      findRunBtn().vm.$emit('click');
      await waitForPromises();

      expect(requestHandlers.retryJobMutationHandler).toHaveBeenCalledTimes(1);
      expect(visitUrl).toHaveBeenCalledWith(mockJobRetryMutationData.data.jobRetry.job.webPath);
    });

    it('does not refetch variables after job is rerun', async () => {
      expect(requestHandlers.getJobQueryResponseHandlerWithVariables).toHaveBeenCalledTimes(1);

      findRunBtn().vm.$emit('click');
      await waitForPromises();

      expect(requestHandlers.getJobQueryResponseHandlerWithVariables).toHaveBeenCalledTimes(1);
    });
  });

  describe('when retry mutation is unsuccessful', () => {
    beforeEach(async () => {
      await createComponent({
        props: { isRetryable: true },
        handlers: {
          retryJobMutationHandler: jest.fn().mockRejectedValue({}),
        },
      });
    });

    it('shows an alert with error', async () => {
      findRunBtn().vm.$emit('click');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: JOB_GRAPHQL_ERRORS.jobMutationErrorText,
      });
    });
  });

  describe('updating variables in UI', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest.fn().mockResolvedValue(mockJobResponse),
        },
      });
    });

    it('creates a new variable when user enters a new key value', async () => {
      expect(findAllVariables()).toHaveLength(1);

      await setCiVariableKey();

      expect(findAllVariables()).toHaveLength(2);
    });

    it('does not create extra empty variables', async () => {
      expect(findAllVariables()).toHaveLength(1);

      await setCiVariableKey();

      expect(findAllVariables()).toHaveLength(2);

      await setCiVariableKey();

      expect(findAllVariables()).toHaveLength(2);
    });

    it('removes the correct variable row', async () => {
      const variableKeyNameOne = 'key-one';
      const variableKeyNameThree = 'key-three';

      await setCiVariableKeyByPosition(0, variableKeyNameOne);

      await setCiVariableKeyByPosition(1, 'key-two');

      await setCiVariableKeyByPosition(2, variableKeyNameThree);

      expect(findAllVariables()).toHaveLength(4);

      await findAllDeleteVarBtns().at(1).trigger('click');

      expect(findAllVariables()).toHaveLength(3);

      expect(findAllCiVariableKeys().at(0).element.value).toBe(variableKeyNameOne);
      expect(findAllCiVariableKeys().at(1).element.value).toBe(variableKeyNameThree);
      expect(findAllCiVariableKeys().at(2).element.value).toBe('');
    });

    it('delete variable button should only show when there is more than one variable', async () => {
      expect(findDeleteVarBtn().exists()).toBe(false);

      await setCiVariableKey();

      expect(findDeleteVarBtn().exists()).toBe(true);
    });
  });

  describe('variable delete button placeholder', () => {
    beforeEach(async () => {
      await createComponent({
        handlers: {
          getJobQueryResponseHandlerWithVariables: jest.fn().mockResolvedValue(mockJobResponse),
        },
      });
    });

    it('delete variable button placeholder should only exist when a user cannot remove', () => {
      expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);
    });

    it('does not show the placeholder button', () => {
      expect(findDeleteVarBtnPlaceholder().classes('gl-opacity-0')).toBe(true);
    });

    it('placeholder button will not delete the row on click', async () => {
      expect(findAllCiVariableKeys()).toHaveLength(1);
      expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);

      await findDeleteVarBtnPlaceholder().trigger('click');

      expect(findAllCiVariableKeys()).toHaveLength(1);
      expect(findDeleteVarBtnPlaceholder().exists()).toBe(true);
    });
  });
});
