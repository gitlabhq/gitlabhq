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
      },
      stubs: {
        GlSprintf,
      },
    });
    return waitForPromises();
  };

  const findHeader = () => wrapper.findComponent(DeploymentHeader);
  const findAlert = () => wrapper.findComponent(GlAlert);

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
  });

  describe('etag polling', () => {
    beforeEach(() => {
      deploymentQueryResponse.mockResolvedValue(mockDeploymentFixture);
      environmentQueryResponse.mockResolvedValue(mockEnvironmentFixture);
      return createComponent();
    });

    it('should set up a toggle visiblity hook on mount', () => {
      expect(toggleQueryPollingByVisibility).toHaveBeenCalled();
    });
  });
});
