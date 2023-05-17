import { GlSprintf, GlLink } from '@gitlab/ui';
import { createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import { nextTick } from 'vue';
import { createAlert } from '~/alert';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import { TYPENAME_CI_BUILD } from '~/graphql_shared/constants';
import { JOB_GRAPHQL_ERRORS } from '~/jobs/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import waitForPromises from 'helpers/wait_for_promises';
import { redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import ManualVariablesForm from '~/jobs/components/job/manual_variables_form.vue';
import getJobQuery from '~/jobs/components/job/graphql/queries/get_job.query.graphql';
import playJobMutation from '~/jobs/components/job/graphql/mutations/job_play_with_variables.mutation.graphql';
import {
  mockFullPath,
  mockId,
  mockJobResponse,
  mockJobWithVariablesResponse,
  mockJobPlayMutationData,
  mockJobRetryMutationData,
} from './mock_data';

const localVue = createLocalVue();
jest.mock('~/alert');
localVue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  redirectTo: jest.fn(),
}));

const defaultProvide = {
  projectPath: mockFullPath,
};

describe('Manual Variables Form', () => {
  let wrapper;
  let mockApollo;
  let getJobQueryResponse;

  const createComponent = ({ options = {}, props = {} } = {}) => {
    wrapper = mountExtended(ManualVariablesForm, {
      propsData: {
        jobId: mockId,
        isRetryable: false,
        ...props,
      },
      provide: {
        ...defaultProvide,
      },
      ...options,
    });
  };

  const createComponentWithApollo = ({ props = {} } = {}) => {
    const requestHandlers = [[getJobQuery, getJobQueryResponse]];

    mockApollo = createMockApollo(requestHandlers);

    const options = {
      localVue,
      apolloProvider: mockApollo,
    };

    createComponent({
      props,
      options,
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

  beforeEach(() => {
    getJobQueryResponse = jest.fn();
  });

  afterEach(() => {
    createAlert.mockClear();
  });

  describe('when page renders', () => {
    beforeEach(async () => {
      getJobQueryResponse.mockResolvedValue(mockJobResponse);
      await createComponentWithApollo();
    });

    it('renders help text with provided link', () => {
      expect(findHelpText().exists()).toBe(true);
      expect(findHelpLink().attributes('href')).toBe(
        '/help/ci/variables/index#add-a-cicd-variable-to-a-project',
      );
    });
  });

  describe('when query is unsuccessful', () => {
    beforeEach(async () => {
      getJobQueryResponse.mockRejectedValue({});
      await createComponentWithApollo();
    });

    it('shows an alert with error', () => {
      expect(createAlert).toHaveBeenCalledWith({
        message: JOB_GRAPHQL_ERRORS.jobQueryErrorText,
      });
    });
  });

  describe('when job has not been retried', () => {
    beforeEach(async () => {
      getJobQueryResponse.mockResolvedValue(mockJobWithVariablesResponse);
      await createComponentWithApollo();
    });

    it('does not render the cancel button', () => {
      expect(findCancelBtn().exists()).toBe(false);
      expect(findRunBtn().exists()).toBe(true);
    });
  });

  describe('when job has variables', () => {
    beforeEach(async () => {
      getJobQueryResponse.mockResolvedValue(mockJobWithVariablesResponse);
      await createComponentWithApollo();
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
      await createComponentWithApollo();
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockJobPlayMutationData);
    });

    it('passes variables in correct format', async () => {
      await setCiVariableKey();

      await findCiVariableValue().setValue('new value');

      await findRunBtn().vm.$emit('click');

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: playJobMutation,
        variables: {
          id: convertToGraphQLId(TYPENAME_CI_BUILD, mockId),
          variables: [
            {
              key: 'new key',
              value: 'new value',
            },
          ],
        },
      });
    });

    it('redirects to job properly after job is run', async () => {
      findRunBtn().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
      expect(redirectTo).toHaveBeenCalledWith(mockJobPlayMutationData.data.jobPlay.job.webPath); // eslint-disable-line import/no-deprecated
    });
  });

  describe('when play mutation is unsuccessful', () => {
    beforeEach(async () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue({});
      await createComponentWithApollo();
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
      await createComponentWithApollo({ props: { isRetryable: true } });
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue(mockJobRetryMutationData);
    });

    it('renders cancel button', () => {
      expect(findCancelBtn().exists()).toBe(true);
    });

    it('redirects to job properly after rerun', async () => {
      findRunBtn().vm.$emit('click');
      await waitForPromises();

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
      expect(redirectTo).toHaveBeenCalledWith(mockJobRetryMutationData.data.jobRetry.job.webPath); // eslint-disable-line import/no-deprecated
    });
  });

  describe('when retry mutation is unsuccessful', () => {
    beforeEach(async () => {
      jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue({});
      await createComponentWithApollo({ props: { isRetryable: true } });
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
      getJobQueryResponse.mockResolvedValue(mockJobResponse);
      await createComponentWithApollo();
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
      getJobQueryResponse.mockResolvedValue(mockJobResponse);
      await createComponentWithApollo();
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
