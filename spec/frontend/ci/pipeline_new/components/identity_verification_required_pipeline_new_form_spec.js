import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlForm } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import PipelineAccountVerificationAlert from 'ee_component/vue_shared/components/pipeline_account_verification_alert.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import PipelineNewForm from '~/ci/pipeline_new/components/pipeline_new_form.vue';
import pipelineCreateMutation from '~/ci/pipeline_new/graphql/mutations/create_pipeline.mutation.graphql';
import ciConfigVariablesQuery from '~/ci/pipeline_new/graphql/queries/ci_config_variables.graphql';
import {
  mockIdentityVerificationRequiredError,
  mockEmptyCiConfigVariablesResponse,
  mockProjectId,
} from '../mock_data';

Vue.use(VueApollo);

const pipelinesPath = '/root/project/-/pipelines';
const pipelinesEditorPath = '/root/project/-/ci/editor';
const projectPath = '/root/project/-/pipelines/config_variables';
const defaultBranch = 'main';

describe('Pipeline New Form', () => {
  let wrapper;
  let mock;
  let mockApollo;
  let mockCiConfigVariables;
  let dummySubmitEvent;
  const pipelineCreateMutationHandler = jest.fn();

  const findForm = () => wrapper.findComponent(GlForm);
  const findErrorAlert = () => wrapper.findByTestId('run-pipeline-error-alert');
  const findIdentityVerificationRequiredAlert = () =>
    wrapper.findComponent(PipelineAccountVerificationAlert);

  const createComponentWithApollo = ({ props = {} } = {}) => {
    const handlers = [
      [ciConfigVariablesQuery, mockCiConfigVariables],
      [pipelineCreateMutation, pipelineCreateMutationHandler],
    ];
    mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(PipelineNewForm, {
      apolloProvider: mockApollo,
      provide: {
        identityVerificationRequired: true,
        identityVerificationPath: '/test',
      },
      propsData: {
        projectId: mockProjectId,
        pipelinesPath,
        pipelinesEditorPath,
        canViewPipelineEditor: true,
        projectPath,
        defaultBranch,
        refParam: defaultBranch,
        settingsLink: '',
        maxWarnings: 25,
        isMaintainer: false,
        ...props,
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mockCiConfigVariables = jest.fn();

    dummySubmitEvent = {
      preventDefault: jest.fn(),
    };
  });

  afterEach(() => {
    mock.restore();
  });

  describe('Form errors and warnings', () => {
    describe('when the error response is identity verification required', () => {
      beforeEach(async () => {
        pipelineCreateMutationHandler.mockResolvedValue(mockIdentityVerificationRequiredError);
        mockCiConfigVariables.mockResolvedValue(mockEmptyCiConfigVariablesResponse);
        createComponentWithApollo();

        findForm().vm.$emit('submit', dummySubmitEvent);

        await waitForPromises();
      });

      it('shows identity verification required alert', () => {
        expect(findErrorAlert().exists()).toBe(false);
        expect(findIdentityVerificationRequiredAlert().exists()).toBe(true);
      });
    });
  });
});
