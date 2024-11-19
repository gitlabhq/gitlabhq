import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import { GlAlert, GlSprintf } from '@gitlab/ui';
import mockDeploymentFixture from 'test_fixtures/graphql/deployments/graphql/queries/deployment.query.graphql.json';
import mockEnvironmentFixture from 'test_fixtures/graphql/deployments/graphql/queries/environment.query.graphql.json';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import { toggleQueryPollingByVisibility } from '~/graphql_shared/utils';
import ShowDeployment from '~/deployments/components/show_deployment.vue';
import DeploymentHeader from '~/deployments/components/deployment_header.vue';
import DeploymentDeployBlock from '~/deployments/components/deployment_deploy_block.vue';
import DetailsFeedback from '~/deployments/components/details_feedback.vue';
import DeploymentAside from '~/deployments/components/deployment_aside.vue';
import ApprovalsEmptyState from 'ee_else_ce/deployments/components/approvals_empty_state.vue';
import deploymentQuery from '~/deployments/graphql/queries/deployment.query.graphql';
import environmentQuery from '~/deployments/graphql/queries/environment.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import createMockApollo from 'helpers/mock_apollo_helper';

jest.mock('~/sentry/sentry_browser_wrapper');
jest.mock('~/graphql_shared/utils');

Vue.use(VueApollo);

const PROJECT_PATH = 'group/project';
const ENVIRONMENT_NAME = mockEnvironmentFixture.data.project.environment.name;
const DEPLOYMENT_IID = mockDeploymentFixture.data.project.deployment.iid;
const GRAPHQL_ETAG_KEY = 'project/environments';
const PROTECTED_ENVIRONMENTS_SETTINGS_PATH = '/settings/ci_cd#js-protected-environments-settings';

describe('~/deployments/components/show_deployment.vue', () => {
  let wrapper;
  let mockApollo;
  let deploymentQueryResponse;
  let environmentQueryResponse;

  beforeEach(() => {
    deploymentQueryResponse = jest.fn();
    environmentQueryResponse = jest.fn();
  });

  const createComponent = () => {
    mockApollo = createMockApollo([
      [deploymentQuery, deploymentQueryResponse],
      [environmentQuery, environmentQueryResponse],
    ]);
    wrapper = shallowMount(ShowDeployment, {
      apolloProvider: mockApollo,
      provide: {
        projectPath: PROJECT_PATH,
        environmentName: ENVIRONMENT_NAME,
        deploymentIid: DEPLOYMENT_IID,
        graphqlEtagKey: GRAPHQL_ETAG_KEY,
        protectedEnvironmentsAvailable: true,
        protectedEnvironmentsSettingsPath: PROTECTED_ENVIRONMENTS_SETTINGS_PATH,
      },
      stubs: {
        GlSprintf,
      },
    });
    return waitForPromises();
  };

  const findHeader = () => wrapper.findComponent(DeploymentHeader);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findApprovalsEmptyState = () => wrapper.findComponent(ApprovalsEmptyState);

  describe('errors', () => {
    it('shows an error message when the deployment query fails', async () => {
      deploymentQueryResponse.mockRejectedValue(new Error());
      await createComponent();

      expect(findAlert().text()).toBe(
        'There was an issue fetching the deployment, please try again later.',
      );
    });

    it('shows an error message when the environment query fails', async () => {
      environmentQueryResponse.mockRejectedValue(new Error());
      await createComponent();

      expect(findAlert().text()).toBe(
        'There was an issue fetching the deployment, please try again later.',
      );
    });

    it('captures exceptions for sentry', async () => {
      const error = new Error('oops!');
      deploymentQueryResponse.mockRejectedValue(error);
      await createComponent();

      expect(captureException).toHaveBeenCalledWith(error);
    });
  });

  describe('loading', () => {
    beforeEach(() => {
      createComponent();
    });

    it('shows the header component in a loading state', () => {
      expect(findHeader().props('loading')).toBe(true);
    });

    it('shows the aside component in a loading state', () => {
      expect(wrapper.findComponent(DeploymentAside).props('loading')).toBe(true);
    });

    it("doesn't show the approvals empty state", () => {
      expect(findApprovalsEmptyState().exists()).toBe(false);
    });
  });

  describe('page', () => {
    beforeEach(() => {
      deploymentQueryResponse.mockResolvedValue(mockDeploymentFixture);
      environmentQueryResponse.mockResolvedValue(mockEnvironmentFixture);
      return createComponent();
    });

    it('shows a header containing the deployment iid', () => {
      expect(wrapper.find('h1').text()).toBe(
        `Deployment #${mockDeploymentFixture.data.project.deployment.iid}`,
      );
    });

    it('shows the header component, binding the environment and deployment', () => {
      expect(findHeader().props()).toMatchObject({
        deployment: mockDeploymentFixture.data.project.deployment,
        environment: mockEnvironmentFixture.data.project.environment,
      });
    });

    it('shows an alert asking for feedback', () => {
      expect(wrapper.findComponent(DetailsFeedback).exists()).toBe(true);
    });

    it('shows the deployment block if the deployment job is manual', () => {
      expect(wrapper.findComponent(DeploymentDeployBlock).props()).toEqual({
        deployment: mockDeploymentFixture.data.project.deployment,
      });
    });

    it('shows the approvals empty state', () => {
      expect(findApprovalsEmptyState().exists()).toBe(true);
    });
  });

  describe('etag polling', () => {
    beforeEach(() => {
      deploymentQueryResponse.mockResolvedValue(mockDeploymentFixture);
      environmentQueryResponse.mockResolvedValue(mockEnvironmentFixture);
      return createComponent();
    });

    it('should set up a toggle visibility hook on mount', () => {
      expect(toggleQueryPollingByVisibility).toHaveBeenCalled();
    });
  });
});
