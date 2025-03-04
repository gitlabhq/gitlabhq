import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import mockPipelineCreateMutationResponse from 'test_fixtures/graphql/pipelines/create_pipeline.mutation.graphql.json';
import mockPipelineCreateMutationErrorResponse from 'test_fixtures/graphql/pipelines/create_pipeline_error.mutation.graphql.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR } from '~/lib/utils/http_status';
import { visitUrl } from '~/lib/utils/url_utility';
import PipelineInputsForm from '~/ci/common/pipeline_inputs/pipeline_inputs_form.vue';
import PipelineNewForm from '~/ci/pipeline_new/components/pipeline_new_form.vue';
import PipelineVariablesForm from '~/ci/pipeline_new/components/pipeline_variables_form.vue';
import pipelineCreateMutation from '~/ci/pipeline_new/graphql/mutations/create_pipeline.mutation.graphql';
import RefsDropdown from '~/ci/pipeline_new/components/refs_dropdown.vue';
import { mockProjectId, mockPipelineConfigButtonText } from '../mock_data';

Vue.directive('safe-html', {
  bind(el, binding) {
    el.innerHTML = binding.value;
  },
});

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  visitUrl: jest.fn(),
  joinPaths: jest.fn(),
  setUrlFragment: jest.fn(),
}));

const defaultProps = {
  projectId: mockProjectId,
  pipelinesPath: '/root/project/-/pipelines',
  pipelinesEditorPath: '/root/project/-/ci/editor',
  canViewPipelineEditor: true,
  projectPath: '/root/project/-/pipelines/config_variables',
  defaultBranch: 'main',
  refParam: 'main',
  settingsLink: '',
  maxWarnings: 25,
  isMaintainer: true,
};

describe('Pipeline New Form', () => {
  let wrapper;
  let mock;
  let mockApollo;
  let dummySubmitEvent;

  const pipelineCreateMutationHandler = jest.fn();

  const findForm = () => wrapper.findComponent(GlForm);
  const findPipelineInputsForm = () => wrapper.findComponent(PipelineInputsForm);
  const findPipelineVariablesForm = () => wrapper.findComponent(PipelineVariablesForm);
  const findRefsDropdown = () => wrapper.findComponent(RefsDropdown);
  const findSubmitButton = () => wrapper.findByTestId('run-pipeline-button');
  const findErrorAlert = () => wrapper.findByTestId('run-pipeline-error-alert');
  const findPipelineConfigButton = () => wrapper.findByTestId('ci-cd-pipeline-configuration');
  const findWarningAlert = () => wrapper.findByTestId('run-pipeline-warning-alert');

  const selectBranch = async (branch) => {
    findRefsDropdown().vm.$emit('input', {
      shortName: branch,
      fullName: `refs/heads/${branch}`,
    });
    await waitForPromises();
  };

  const createComponentWithApollo = async ({
    props = {},
    mountFn = shallowMountExtended,
    stubs = {},
    ciInputsForPipelines = false,
  } = {}) => {
    const handlers = [[pipelineCreateMutation, pipelineCreateMutationHandler]];
    mockApollo = createMockApollo(handlers);
    wrapper = mountFn(PipelineNewForm, {
      apolloProvider: mockApollo,
      provide: {
        identityVerificationRequired: true,
        identityVerificationPath: '/test',
        glFeatures: {
          ciInputsForPipelines,
        },
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs,
    });

    await waitForPromises();
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    dummySubmitEvent = {
      preventDefault: jest.fn(),
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('Feature flag', () => {
    describe('when the ciInputsForPipelines flag is disabled', () => {
      beforeEach(async () => {
        createComponentWithApollo();
        await waitForPromises();
      });

      it('does not display the pipeline inputs form component', () => {
        expect(findPipelineInputsForm().exists()).toBe(false);
      });
    });

    describe('when the ciInputsForPipelines flag is enabled', () => {
      beforeEach(async () => {
        createComponentWithApollo({ ciInputsForPipelines: true });
        await waitForPromises();
      });

      it('displays the pipeline inputs form component', () => {
        expect(findPipelineInputsForm().exists()).toBe(true);
      });
    });
  });

  describe('When the ref is changed', () => {
    beforeEach(async () => {
      await createComponentWithApollo();
    });

    it('updates when a new branch is selected', async () => {
      await selectBranch('branch-1');

      expect(findRefsDropdown().props('value')).toEqual({
        shortName: 'branch-1',
        fullName: 'refs/heads/branch-1',
      });
    });
  });

  describe('Pipeline variables form', () => {
    beforeEach(async () => {
      pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationResponse);
      await createComponentWithApollo();
    });

    it('renders the pipeline variables form component', () => {
      expect(findPipelineVariablesForm().exists()).toBe(true);
      expect(findPipelineVariablesForm().props()).toMatchObject({
        isMaintainer: true,
        projectPath: defaultProps.projectPath,
        refParam: `refs/heads/${defaultProps.refParam}`,
        settingsLink: '',
      });
    });

    it('passes variables to the create mutation', async () => {
      const variables = [{ key: 'TEST_VAR', value: 'test_value' }];
      findPipelineVariablesForm().vm.$emit('variables-updated', variables);
      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(pipelineCreateMutationHandler).toHaveBeenCalledWith({
        input: {
          ref: 'main',
          projectPath: '/root/project/-/pipelines/config_variables',
          variables,
        },
      });
    });
  });

  describe('Pipeline creation', () => {
    beforeEach(() => {
      pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationResponse);
    });

    it('does not submit the native HTML form', async () => {
      await createComponentWithApollo();
      findForm().vm.$emit('submit', dummySubmitEvent);

      expect(dummySubmitEvent.preventDefault).toHaveBeenCalled();
    });

    it('disables the submit button immediately after submitting', async () => {
      await createComponentWithApollo();
      expect(findSubmitButton().props('disabled')).toBe(false);
      await findForm().vm.$emit('submit', dummySubmitEvent);

      expect(findSubmitButton().props('disabled')).toBe(true);
    });

    it('fires the mutation when the submit button is clicked', async () => {
      await createComponentWithApollo();
      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(pipelineCreateMutationHandler).toHaveBeenCalled();
    });

    it('creates pipeline with ref and variables', async () => {
      await createComponentWithApollo();
      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(pipelineCreateMutationHandler).toHaveBeenCalledWith({
        input: {
          ref: 'main',
          projectPath: '/root/project/-/pipelines/config_variables',
          variables: [],
        },
      });
    });

    it('navigates to the created pipeline', async () => {
      const pipelinePath = mockPipelineCreateMutationResponse.data.pipelineCreate.pipeline.path;
      await createComponentWithApollo();
      findForm().vm.$emit('submit', dummySubmitEvent);
      await waitForPromises();

      expect(visitUrl).toHaveBeenCalledWith(pipelinePath);
    });
  });

  describe('Form errors and warnings', () => {
    beforeEach(async () => {
      await createComponentWithApollo();
    });

    describe('when the refs cannot be loaded', () => {
      beforeEach(async () => {
        await createComponentWithApollo();
        mock
          .onGet(`/api/v4/projects/${mockProjectId}/repository/branches`, {
            params: { search: '' },
          })
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR);
        findRefsDropdown().vm.$emit('loadingError');
        await waitForPromises();
      });

      it('shows an error alert', () => {
        expect(findErrorAlert().exists()).toBe(true);
        expect(findWarningAlert().exists()).toBe(false);
      });
    });

    describe('when pipeline creation mutation is not successful', () => {
      beforeEach(async () => {
        pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationErrorResponse);
        await createComponentWithApollo();
        findForm().vm.$emit('submit', dummySubmitEvent);
        await waitForPromises();
      });

      it('shows error alert', () => {
        expect(findErrorAlert().exists()).toBe(true);
      });

      it('shows the correct error', () => {
        const error = mockPipelineCreateMutationErrorResponse.data.pipelineCreate.errors[0];

        expect(wrapper.vm.error).toBe(error);
      });

      it('re-enables the submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(false);
      });

      it('shows pipeline configuration button for user who can view', () => {
        expect(findPipelineConfigButton().exists()).toBe(true);
        expect(findPipelineConfigButton().text()).toBe(mockPipelineConfigButtonText);
      });

      it('does not show pipeline configuration button for user who cannot view', async () => {
        await createComponentWithApollo({
          props: { canViewPipelineEditor: false },
        });

        expect(findPipelineConfigButton().exists()).toBe(false);
      });
    });

    describe('when the error response cannot be handled', () => {
      beforeEach(async () => {
        mock
          .onPost(defaultProps.pipelinesPath)
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, 'something went wrong');
        findForm().vm.$emit('submit', dummySubmitEvent);
        await waitForPromises();
      });

      it('re-enables the submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(false);
      });
    });
  });
});
