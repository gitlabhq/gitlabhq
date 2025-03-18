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
import { mockPipelineVariablesPermissions } from 'jest/ci/job_details/mock_data';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
  defaultBranch: 'main',
  refParam: 'main',
  settingsLink: '',
  maxWarnings: 25,
  isMaintainer: true,
};

const defaultProvide = {
  canViewPipelineEditor: true,
  identityVerificationRequired: true,
  identityVerificationPath: '/test',
  pipelineEditorPath: '/root/project/-/ci/editor',
  pipelinesPath: '/root/project/-/pipelines',
  projectPath: '/root/project/-/pipelines/config_variables',
  userRole: 'Maintainer',
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

  const submitForm = async () => {
    findForm().vm.$emit('submit', dummySubmitEvent);
    await waitForPromises();
  };

  const selectBranch = async (branch) => {
    findRefsDropdown().vm.$emit('input', {
      shortName: branch,
      fullName: `refs/heads/${branch}`,
    });
    await waitForPromises();
  };

  const createComponentWithApollo = async ({
    props = {},
    provide = {},
    mountFn = shallowMountExtended,
    stubs = {},
    ciInputsForPipelines = false,
    pipelineVariablesPermissionsMixin = mockPipelineVariablesPermissions(true),
  } = {}) => {
    const handlers = [[pipelineCreateMutation, pipelineCreateMutationHandler]];
    mockApollo = createMockApollo(handlers);
    wrapper = mountFn(PipelineNewForm, {
      apolloProvider: mockApollo,
      provide: {
        ...defaultProvide,
        ...provide,
        glFeatures: {
          ciInputsForPipelines,
        },
      },
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs,
      mixins: [glFeatureFlagMixin(), pipelineVariablesPermissionsMixin],
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
    beforeEach(() => {
      pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationResponse);
    });
    describe('when the ciInputsForPipelines flag is disabled', () => {
      beforeEach(async () => {
        createComponentWithApollo();
        await waitForPromises();
      });

      it('does not display the pipeline inputs form component', () => {
        expect(findPipelineInputsForm().exists()).toBe(false);
      });

      it('does not include inputs in the mutation variables', async () => {
        await submitForm();

        expect(pipelineCreateMutationHandler).toHaveBeenCalledWith({
          input: {
            ref: 'main',
            projectPath: defaultProvide.projectPath,
            variables: [],
          },
        });
      });
    });

    describe('when the ciInputsForPipelines flag is enabled', () => {
      beforeEach(async () => {
        createComponentWithApollo({ ciInputsForPipelines: true });
        await waitForPromises();
      });

      it('displays the pipeline inputs form component', () => {
        expect(findPipelineInputsForm().exists()).toBe(true);
        expect(findPipelineInputsForm().props()).toMatchObject({
          queryRef: `refs/heads/${defaultProps.refParam}`,
        });
      });

      it('includes inputs in the mutation variables', async () => {
        await submitForm();

        expect(pipelineCreateMutationHandler).toHaveBeenCalledWith({
          input: {
            ref: 'main',
            projectPath: defaultProvide.projectPath,
            inputs: [],
            variables: [],
          },
        });
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

  describe('Pipeline inputs form', () => {
    beforeEach(async () => {
      await createComponentWithApollo({ ciInputsForPipelines: true });
    });

    it('updates inputs when inputs-updated event is emitted', async () => {
      const updatedInputs = [{ name: 'TEST_INPUT', value: 'test_value' }];
      findPipelineInputsForm().vm.$emit('update-inputs', updatedInputs);
      await waitForPromises();

      expect(wrapper.vm.pipelineInputs).toEqual(updatedInputs);
    });
  });

  describe('Pipeline variables form', () => {
    describe('when user has permission to view variables', () => {
      it('renders the pipeline variables form component', async () => {
        pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationResponse);
        await createComponentWithApollo();

        expect(findPipelineVariablesForm().exists()).toBe(true);
        expect(findPipelineVariablesForm().props()).toMatchObject({
          isMaintainer: true,
          refParam: `refs/heads/${defaultProps.refParam}`,
          settingsLink: '',
        });
      });

      it('passes variables to the create mutation', async () => {
        pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationResponse);
        await createComponentWithApollo();

        const variables = [{ key: 'TEST_VAR', value: 'test_value' }];
        findPipelineVariablesForm().vm.$emit('variables-updated', variables);
        await submitForm();

        expect(pipelineCreateMutationHandler).toHaveBeenCalledWith({
          input: {
            ref: 'main',
            projectPath: defaultProvide.projectPath,
            variables,
          },
        });
      });

      describe('ref param', () => {
        it('provides refParam as ref.fullName when available', async () => {
          pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationResponse);
          await createComponentWithApollo();

          expect(findPipelineVariablesForm().props('refParam')).toBe(
            `refs/heads/${defaultProps.refParam}`,
          );
        });

        it('provides refParam as ref.shortName when available', async () => {
          pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationResponse);
          await createComponentWithApollo({ props: { refParam: 'another-branch' } });

          expect(findPipelineVariablesForm().props('refParam')).toBe('another-branch');
        });
      });
    });

    describe('when user does not have permission to view variables', () => {
      beforeEach(async () => {
        pipelineCreateMutationHandler.mockResolvedValue(mockPipelineCreateMutationResponse);
        await createComponentWithApollo({
          pipelineVariablesPermissionsMixin: mockPipelineVariablesPermissions(false),
        });
      });

      it('does not render the pipeline variables form component', () => {
        expect(findPipelineVariablesForm().exists()).toBe(false);
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
      await submitForm();

      expect(pipelineCreateMutationHandler).toHaveBeenCalled();
    });

    it('creates pipeline with ref and variables', async () => {
      await createComponentWithApollo();
      await submitForm();

      expect(pipelineCreateMutationHandler).toHaveBeenCalledWith({
        input: {
          ref: 'main',
          projectPath: defaultProvide.projectPath,
          variables: [],
        },
      });
    });

    it('navigates to the created pipeline', async () => {
      const pipelinePath = mockPipelineCreateMutationResponse.data.pipelineCreate.pipeline.path;
      await createComponentWithApollo();
      await submitForm();

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
        await submitForm();
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
          provide: { canViewPipelineEditor: false },
        });

        expect(findPipelineConfigButton().exists()).toBe(false);
      });
    });

    describe('when the error response cannot be handled', () => {
      beforeEach(async () => {
        mock
          .onPost(defaultProps.pipelinesPath)
          .reply(HTTP_STATUS_INTERNAL_SERVER_ERROR, 'something went wrong');
        await submitForm();
      });

      it('re-enables the submit button', () => {
        expect(findSubmitButton().props('disabled')).toBe(false);
      });
    });
  });
});
