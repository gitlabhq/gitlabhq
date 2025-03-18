import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { createAlert } from '~/alert';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TYPENAME_CI_BUILD } from '~/graphql_shared/constants';
import { JOB_GRAPHQL_ERRORS } from '~/ci/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import waitForPromises from 'helpers/wait_for_promises';
import { visitUrl } from '~/lib/utils/url_utility';
import ManualJobForm from '~/ci/job_details/components/manual_job_form.vue';
import playJobMutation from '~/ci/job_details/graphql/mutations/job_play_with_variables.mutation.graphql';
import retryJobMutation from '~/ci/job_details/graphql/mutations/job_retry_with_variables.mutation.graphql';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import JobVariablesForm from '~/ci/job_details/components/job_variables_form.vue';

import {
  mockFullPath,
  mockId,
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

const defaultProps = {
  jobId: mockId,
  jobName: 'job-name',
  isRetryable: false,
  canViewPipelineVariables: true,
};

const defaultProvide = {
  projectPath: mockFullPath,
};

describe('Manual Variables Form', () => {
  let wrapper;
  let mockApollo;
  let requestHandlers;

  const playJobMutationHandler = jest.fn().mockResolvedValue({});
  const retryJobMutationHandler = jest.fn().mockResolvedValue({});

  const defaultHandlers = {
    playJobMutationHandler,
    retryJobMutationHandler,
  };

  const createComponent = ({ props = {}, handlers = defaultHandlers } = {}) => {
    requestHandlers = handlers;

    mockApollo = createMockApollo([
      [playJobMutation, handlers.playJobMutationHandler],
      [retryJobMutation, handlers.retryJobMutationHandler],
    ]);

    const options = {
      apolloProvider: mockApollo,
    };

    wrapper = shallowMountExtended(ManualJobForm, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
      },
      ...options,
    });
  };

  const findCancelBtn = () => wrapper.findByTestId('cancel-btn');
  const findRunBtn = () => wrapper.findByTestId('run-manual-job-btn');
  const findVariablesForm = () => wrapper.findComponent(JobVariablesForm);

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('when page renders', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders job id to variables form', () => {
      expect(findVariablesForm().exists()).toBe(true);
    });

    it('provides job variables form', () => {
      expect(findVariablesForm().props('jobId')).toBe(mockId);
    });
  });

  describe('when job has not been retried', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render the cancel button', () => {
      expect(findCancelBtn().exists()).toBe(false);
      expect(findRunBtn().exists()).toBe(true);
    });
  });

  describe('when play mutation fires', () => {
    beforeEach(() => {
      createComponent({
        handlers: {
          playJobMutationHandler: jest.fn().mockResolvedValue(mockJobPlayMutationData),
        },
      });
    });

    it('passes variables in correct format', () => {
      findVariablesForm().vm.$emit('update-variables', [
        {
          id: 'gid://gitlab/Ci::JobVariable/6',
          key: 'new key',
          value: 'new value',
        },
      ]);

      findRunBtn().vm.$emit('click');

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
    beforeEach(() => {
      createComponent({
        props: { isRetryable: true },
        handlers: {
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
      beforeEach(() => {
        createComponent({
          props: {
            isRetryable: true,
            confirmationMessage: 'Are you sure?',
          },
          handlers: {
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
  });

  describe('when retry mutation is unsuccessful', () => {
    beforeEach(() => {
      createComponent({
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

  describe('when the user is not allowed to see the pipeline variables', () => {
    beforeEach(() => {
      createComponent({
        props: { canViewPipelineVariables: false },
      });
    });

    it('does not render job variables form', () => {
      expect(findVariablesForm().exists()).toBe(false);
    });
  });
});
