import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlLink, GlSprintf } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import EnvironmentItem from '~/environments/components/new_environment_item.vue';
import EnvironmentActions from '~/environments/components/environment_actions.vue';
import Rollback from '~/environments/components/environment_rollback.vue';
import ExternalUrl from '~/environments/components/environment_external_url.vue';
import StopComponent from '~/environments/components/environment_stop.vue';
import Pin from '~/environments/components/environment_pin.vue';
import Terminal from '~/environments/components/environment_terminal_button.vue';
import Delete from '~/environments/components/environment_delete.vue';
import Deployment from '~/environments/components/deployment.vue';
import DeployBoardWrapper from '~/environments/components/deploy_board_wrapper.vue';
import { resolvedEnvironment, rolloutStatus } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/new_environment_item.vue', () => {
  let wrapper;

  const createApolloProvider = () => {
    return createMockApollo();
  };

  const createWrapper = ({ propsData = {}, provideData = {}, apolloProvider } = {}) =>
    shallowMountExtended(EnvironmentItem, {
      apolloProvider,
      propsData: { environment: resolvedEnvironment, ...propsData },
      provide: {
        helpPagePath: '/help',
        projectId: '1',
        projectPath: '/1',
        ...provideData,
      },
      stubs: { GlSprintf, TimeAgoTooltip },
    });

  const findDeployment = () => wrapper.findComponent(Deployment);
  const findActions = () => wrapper.findComponent(EnvironmentActions);
  const findNameLink = () => wrapper.findComponent(GlLink);
  const findEmptyState = () => wrapper.findByTestId('deployments-empty-state');

  it('displays the name when not in a folder', () => {
    wrapper = createWrapper({ apolloProvider: createApolloProvider() });

    expect(findNameLink().text()).toBe(resolvedEnvironment.name);
  });

  it('displays the name minus the folder prefix when in a folder', () => {
    wrapper = createWrapper({
      propsData: { inFolder: true },
      apolloProvider: createApolloProvider(),
    });

    expect(findNameLink().text()).toBe(resolvedEnvironment.nameWithoutType);
  });

  it('truncates the name if it is very long', () => {
    const environment = {
      ...resolvedEnvironment,
      name: 'this is a really long name that should be truncated because otherwise it would look strange in the UI',
    };
    wrapper = createWrapper({ propsData: { environment }, apolloProvider: createApolloProvider() });

    expect(findNameLink().text()).toHaveLength(80);
  });

  describe('tier', () => {
    it('displays the tier of the environment when defined in yaml', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const tier = wrapper.findByTitle('Deployment tier');

      expect(tier.text()).toBe(resolvedEnvironment.lastDeployment.tierInYaml);
    });

    it('does not display the tier if not defined in yaml', () => {
      const environment = {
        ...resolvedEnvironment,
        lastDeployment: {
          ...resolvedEnvironment.lastDeployment,
          tierInYaml: null,
        },
      };
      wrapper = createWrapper({
        propsData: { environment },
        apolloProvider: createApolloProvider(),
      });

      const tier = wrapper.findByTitle('Deployment tier');

      expect(tier.exists()).toBe(false);
    });
  });

  describe('external url', () => {
    const findExternalUrl = () => wrapper.findComponent(ExternalUrl);

    it('shows a link for the url if one is present', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      expect(findExternalUrl().props('externalUrl')).toEqual(resolvedEnvironment.externalUrl);
    });

    it('does not show a link for the url if one is missing', () => {
      wrapper = createWrapper({
        propsData: { environment: { ...resolvedEnvironment, externalUrl: '' } },
        apolloProvider: createApolloProvider(),
      });

      expect(findExternalUrl().exists()).toBe(false);
    });
  });

  describe('actions', () => {
    it('shows a dropdown if there are actions to perform', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      expect(findActions().exists()).toBe(true);
    });

    it('does not show a dropdown if there are no actions to perform', () => {
      wrapper = createWrapper({
        propsData: {
          environment: {
            ...resolvedEnvironment,
            lastDeployment: null,
          },
          apolloProvider: createApolloProvider(),
        },
      });

      expect(findActions().exists()).toBe(false);
    });

    it('passes all the actions down to the action component', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      expect(findActions().props('actions')).toMatchObject(
        resolvedEnvironment.lastDeployment.manualActions,
      );
    });
  });

  describe('stop', () => {
    const findStopComponent = () => wrapper.findComponent(StopComponent);

    it('shows a button to stop the environment if the environment is available', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      expect(findStopComponent().props('environment')).toBe(resolvedEnvironment);
    });

    it('does not show a button to stop the environment if the environment is stopped', () => {
      wrapper = createWrapper({
        propsData: { environment: { ...resolvedEnvironment, canStop: false } },
        apolloProvider: createApolloProvider(),
      });

      expect(findStopComponent().exists()).toBe(false);
    });
  });

  describe('rollback', () => {
    it('renders rollback component with the correct props when lastDeployment is available', async () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });
      await waitForPromises();

      const rollback = wrapper.findComponent(Rollback);
      expect(rollback.props()).toEqual({
        environment: resolvedEnvironment,
        isLastDeployment: true,
        retryUrl: resolvedEnvironment.lastDeployment.deployable.retryPath,
        graphql: true,
      });
    });

    it("doesn't render rollback component when lastDeployment is not available", async () => {
      wrapper = createWrapper({
        propsData: { environment: { ...resolvedEnvironment, lastDeployment: null } },
        apolloProvider: createApolloProvider(),
      });
      await waitForPromises();

      const rollback = wrapper.findComponent(Rollback);
      expect(rollback.exists()).toBe(false);
    });
  });

  describe('pin', () => {
    const findPin = () => wrapper.findComponent(Pin);
    const findAutoStopTime = () => wrapper.findByTestId('auto-stop-time');

    describe('with autostop', () => {
      let environment;

      beforeEach(() => {
        environment = {
          ...resolvedEnvironment,
          autoStopAt: new Date(Date.now() + 100000).toString(),
        };
        wrapper = createWrapper({
          propsData: {
            environment,
          },
          apolloProvider: createApolloProvider(),
        });
      });

      it('shows the option to pin the environment if there is an autostop date', () => {
        expect(findPin().props('autoStopUrl')).toBe(resolvedEnvironment.cancelAutoStopPath);
      });

      it('shows time when the environment auto stops', () => {
        expect(findAutoStopTime().text()).toBe('Auto stop in 1 minute');
      });
    });

    describe('without autostop', () => {
      beforeEach(() => {
        wrapper = createWrapper({ apolloProvider: createApolloProvider() });
      });

      it('does not show the option to pin the environment if there is no autostop date', () => {
        wrapper = createWrapper({ apolloProvider: createApolloProvider() });

        expect(findPin().exists()).toBe(false);
      });

      it('does not show when the environment auto stops', () => {
        expect(findAutoStopTime().exists()).toBe(false);
      });
    });

    describe('with past autostop', () => {
      let environment;

      beforeEach(() => {
        environment = {
          ...resolvedEnvironment,
          autoStopAt: new Date(Date.now() - 100000).toString(),
        };
        wrapper = createWrapper({
          propsData: {
            environment,
          },
          apolloProvider: createApolloProvider(),
        });
      });

      it('does not show the option to pin the environment if there is no autostop date', () => {
        wrapper = createWrapper({ apolloProvider: createApolloProvider() });

        expect(findPin().exists()).toBe(false);
      });

      it('does not show when the environment auto stops', () => {
        expect(findAutoStopTime().exists()).toBe(false);
      });
    });
  });

  describe('terminal', () => {
    const findTerminal = () => wrapper.findComponent(Terminal);

    it('shows the link to the terminal if set up', () => {
      wrapper = createWrapper({
        propsData: { environment: { ...resolvedEnvironment, terminalPath: '/terminal' } },
        apolloProvider: createApolloProvider(),
      });

      expect(findTerminal().props('terminalPath')).toEqual('/terminal');
    });

    it('does not show the link to the terminal if not set up', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      expect(findTerminal().exists()).toBe(false);
    });
  });

  describe('delete', () => {
    const findDelete = () => wrapper.findComponent(Delete);

    it('shows the button to delete the environment if possible', () => {
      const deletableEnvironment = {
        ...resolvedEnvironment,
        canDelete: true,
        deletePath: '/terminal',
      };

      wrapper = createWrapper({
        propsData: {
          environment: deletableEnvironment,
        },
        apolloProvider: createApolloProvider(),
      });

      expect(findDelete().props('environment')).toEqual(deletableEnvironment);
    });

    it('does not show the button to delete the environment if not possible', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      expect(findDelete().exists()).toBe(false);
    });
  });

  describe('last deployment', () => {
    it('should pass the last deployment to the deployment component when it exists', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const deployment = findDeployment();
      expect(deployment.props('deployment')).toEqual(resolvedEnvironment.lastDeployment);
    });
    it('should not show the last deployment when it is missing', () => {
      const environment = {
        ...resolvedEnvironment,
        lastDeployment: null,
      };

      wrapper = createWrapper({
        propsData: { environment },
        apolloProvider: createApolloProvider(),
      });

      const deployment = findDeployment();
      expect(deployment.exists()).toBe(false);
    });
  });

  describe('upcoming deployment', () => {
    it('should pass the upcoming deployment to the deployment component when it exists', () => {
      const upcomingDeployment = resolvedEnvironment.lastDeployment;
      const environment = { ...resolvedEnvironment, lastDeployment: null, upcomingDeployment };
      wrapper = createWrapper({
        propsData: { environment },
        apolloProvider: createApolloProvider(),
      });

      const deployment = findDeployment();
      expect(deployment.props('deployment')).toMatchObject(upcomingDeployment);
    });
    it('should not show the upcoming deployment when it is missing', () => {
      const environment = {
        ...resolvedEnvironment,
        lastDeployment: null,
        upcomingDeployment: null,
      };

      wrapper = createWrapper({
        propsData: { environment },
        apolloProvider: createApolloProvider(),
      });

      const deployment = findDeployment();
      expect(deployment.exists()).toBe(false);
    });
  });

  describe('empty state', () => {
    it('should link to documentation', () => {
      const environment = {
        ...resolvedEnvironment,
        lastDeployment: null,
        upcomingDeployment: null,
      };

      wrapper = createWrapper({
        propsData: { environment },
        apolloProvider: createApolloProvider(),
      });

      expect(findEmptyState().text()).toBe(
        'There are no deployments for this environment yet. Learn more about setting up deployments.',
      );
      expect(findEmptyState().findComponent(GlLink).attributes('href')).toBe('/help');
    });

    it('should not show empty state when there are deployments', () => {
      wrapper = createWrapper({
        apolloProvider: createApolloProvider(),
      });

      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('deploy boards', () => {
    it('should show a deploy board if the environment has a rollout status', () => {
      const environment = {
        ...resolvedEnvironment,
        rolloutStatus,
      };

      wrapper = createWrapper({
        propsData: { environment },
        apolloProvider: createApolloProvider(),
      });

      const deployBoard = wrapper.findComponent(DeployBoardWrapper);
      expect(deployBoard.exists()).toBe(true);
      expect(deployBoard.props('rolloutStatus')).toBe(rolloutStatus);
    });

    it('should not show a deploy board if the environment has no rollout status', () => {
      wrapper = createWrapper({
        apolloProvider: createApolloProvider(),
      });
      const deployBoard = wrapper.findComponent(DeployBoardWrapper);
      expect(deployBoard.exists()).toBe(false);
    });
  });
});
