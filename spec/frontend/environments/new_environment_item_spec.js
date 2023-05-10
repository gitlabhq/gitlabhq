import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlCollapse, GlIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import { stubTransition } from 'helpers/stub_transition';
import { formatDate, getTimeago } from '~/lib/utils/datetime_utility';
import { __, s__, sprintf } from '~/locale';
import EnvironmentItem from '~/environments/components/new_environment_item.vue';
import EnvironmentActions from '~/environments/components/environment_actions.vue';
import Deployment from '~/environments/components/deployment.vue';
import DeployBoardWrapper from '~/environments/components/deploy_board_wrapper.vue';
import KubernetesOverview from '~/environments/components/kubernetes_overview.vue';
import { resolvedEnvironment, rolloutStatus, agent } from './graphql/mock_data';
import { mockKasTunnelUrl } from './mock_data';

Vue.use(VueApollo);

describe('~/environments/components/new_environment_item.vue', () => {
  let wrapper;

  const createApolloProvider = () => {
    return createMockApollo();
  };

  const createWrapper = ({ propsData = {}, provideData = {}, apolloProvider } = {}) =>
    mountExtended(EnvironmentItem, {
      apolloProvider,
      propsData: { environment: resolvedEnvironment, ...propsData },
      provide: {
        helpPagePath: '/help',
        projectId: '1',
        projectPath: '/1',
        kasTunnelUrl: mockKasTunnelUrl,
        ...provideData,
      },
      stubs: { transition: stubTransition() },
    });

  const findDeployment = () => wrapper.findComponent(Deployment);
  const findActions = () => wrapper.findComponent(EnvironmentActions);
  const findKubernetesOverview = () => wrapper.findComponent(KubernetesOverview);
  const findMonitoringLink = () => wrapper.find('[data-testid="environment-monitoring"]');

  const expandCollapsedSection = async () => {
    const button = wrapper.findByRole('button', { name: __('Expand') });
    await button.trigger('click');

    return button;
  };

  it('displays the name when not in a folder', () => {
    wrapper = createWrapper({ apolloProvider: createApolloProvider() });

    const name = wrapper.findByRole('link', { name: resolvedEnvironment.name });
    expect(name.exists()).toBe(true);
  });

  it('displays the name minus the folder prefix when in a folder', () => {
    wrapper = createWrapper({
      propsData: { inFolder: true },
      apolloProvider: createApolloProvider(),
    });

    const name = wrapper.findByRole('link', { name: resolvedEnvironment.nameWithoutType });
    expect(name.exists()).toBe(true);
  });

  it('truncates the name if it is very long', () => {
    const environment = {
      ...resolvedEnvironment,
      name:
        'this is a really long name that should be truncated because otherwise it would look strange in the UI',
    };
    wrapper = createWrapper({ propsData: { environment }, apolloProvider: createApolloProvider() });

    const name = wrapper.findByRole('link', {
      name: (text) => environment.name.startsWith(text.slice(0, -1)),
    });
    expect(name.exists()).toBe(true);
    expect(name.text()).toHaveLength(80);
  });

  describe('tier', () => {
    it('displays the tier of the environment when defined in yaml', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const tier = wrapper.findByTitle(s__('Environment|Deployment tier'));

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

      const tier = wrapper.findByTitle(s__('Environment|Deployment tier'));

      expect(tier.exists()).toBe(false);
    });
  });

  describe('url', () => {
    it('shows a link for the url if one is present', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const url = wrapper.findByRole('link', { name: s__('Environments|Open live environment') });

      expect(url.attributes('href')).toEqual(resolvedEnvironment.externalUrl);
    });

    it('does not show a link for the url if one is missing', () => {
      wrapper = createWrapper({
        propsData: { environment: { ...resolvedEnvironment, externalUrl: '' } },
        apolloProvider: createApolloProvider(),
      });

      const url = wrapper.findByRole('link', { name: s__('Environments|Open live environment') });

      expect(url.exists()).toBe(false);
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
    it('shows a button to stop the environment if the environment is available', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const stop = wrapper.findByRole('button', { name: s__('Environments|Stop environment') });

      expect(stop.exists()).toBe(true);
    });

    it('does not show a button to stop the environment if the environment is stopped', () => {
      wrapper = createWrapper({
        propsData: { environment: { ...resolvedEnvironment, canStop: false } },
        apolloProvider: createApolloProvider(),
      });

      const stop = wrapper.findByRole('button', { name: s__('Environments|Stop environment') });

      expect(stop.exists()).toBe(false);
    });
  });

  describe('rollback', () => {
    it('shows the option to rollback/re-deploy if available', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const rollback = wrapper.findByRole('menuitem', {
        name: s__('Environments|Re-deploy to environment'),
      });

      expect(rollback.exists()).toBe(true);
    });

    it('does not show the option to rollback/re-deploy if not available', () => {
      wrapper = createWrapper({
        propsData: { environment: { ...resolvedEnvironment, lastDeployment: null } },
        apolloProvider: createApolloProvider(),
      });

      const rollback = wrapper.findByRole('menuitem', {
        name: s__('Environments|Re-deploy to environment'),
      });

      expect(rollback.exists()).toBe(false);
    });
  });

  describe('pin', () => {
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
        const pin = wrapper.findByRole('menuitem', { name: __('Prevent auto-stopping') });

        expect(pin.exists()).toBe(true);
      });

      it('shows when the environment auto stops', () => {
        const autoStop = wrapper.findByTitle(formatDate(environment.autoStopAt));

        expect(autoStop.text()).toBe('in 1 minute');
      });
    });

    describe('without autostop', () => {
      beforeEach(() => {
        wrapper = createWrapper({ apolloProvider: createApolloProvider() });
      });

      it('does not show the option to pin the environment if there is no autostop date', () => {
        wrapper = createWrapper({ apolloProvider: createApolloProvider() });

        const pin = wrapper.findByRole('menuitem', { name: __('Prevent auto-stopping') });

        expect(pin.exists()).toBe(false);
      });

      it('does not show when the environment auto stops', () => {
        const autoStop = wrapper.findByText(
          sprintf(s__('Environment|Auto stop %{time}'), {
            time: getTimeago().format(resolvedEnvironment.autoStopAt),
          }),
        );

        expect(autoStop.exists()).toBe(false);
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

        const pin = wrapper.findByRole('menuitem', { name: __('Prevent auto-stopping') });

        expect(pin.exists()).toBe(false);
      });

      it('does not show when the environment auto stops', () => {
        const autoStop = wrapper.findByText(
          sprintf(s__('Environment|Auto stop %{time}'), {
            time: getTimeago().format(environment.autoStopAt),
          }),
        );

        expect(autoStop.exists()).toBe(false);
      });
    });
  });

  describe('monitoring', () => {
    it('shows the link to monitoring if metrics are set up', () => {
      wrapper = createWrapper({
        propsData: { environment: { ...resolvedEnvironment, metricsPath: '/metrics' } },
        apolloProvider: createApolloProvider(),
      });

      const rollback = wrapper.findByRole('menuitem', { name: __('Monitoring') });

      expect(rollback.exists()).toBe(true);
    });

    it('does not show the link to monitoring if metrics are not set up', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const rollback = wrapper.findByRole('menuitem', { name: __('Monitoring') });

      expect(rollback.exists()).toBe(false);
    });

    describe.each([true, false])(
      'when `remove_monitor_metrics` flag  is %p',
      (removeMonitorMetrics) => {
        beforeEach(() => {
          wrapper = createWrapper({
            propsData: { environment: { ...resolvedEnvironment, metricsPath: '/metrics' } },
            apolloProvider: createApolloProvider(),
            provideData: { glFeatures: { removeMonitorMetrics } },
          });
        });

        it(`${removeMonitorMetrics ? 'does not render' : 'renders'} link to metrics`, () => {
          expect(findMonitoringLink().exists()).toBe(!removeMonitorMetrics);
        });
      },
    );
  });

  describe('terminal', () => {
    it('shows the link to the terminal if set up', () => {
      wrapper = createWrapper({
        propsData: { environment: { ...resolvedEnvironment, terminalPath: '/terminal' } },
        apolloProvider: createApolloProvider(),
      });

      const rollback = wrapper.findByRole('menuitem', { name: __('Terminal') });

      expect(rollback.exists()).toBe(true);
    });

    it('does not show the link to the terminal if not set up', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const rollback = wrapper.findByRole('menuitem', { name: __('Terminal') });

      expect(rollback.exists()).toBe(false);
    });
  });

  describe('delete', () => {
    it('shows the button to delete the environment if possible', () => {
      wrapper = createWrapper({
        propsData: {
          environment: { ...resolvedEnvironment, canDelete: true, deletePath: '/terminal' },
        },
        apolloProvider: createApolloProvider(),
      });

      const rollback = wrapper.findByRole('menuitem', {
        name: s__('Environments|Delete environment'),
      });

      expect(rollback.exists()).toBe(true);
    });

    it('does not show the button to delete the environment if not possible', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const rollback = wrapper.findByRole('menuitem', {
        name: s__('Environments|Delete environment'),
      });

      expect(rollback.exists()).toBe(false);
    });
  });

  describe('collapse', () => {
    let icon;
    let collapse;
    let environmentName;

    beforeEach(() => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });
      collapse = wrapper.findComponent(GlCollapse);
      icon = wrapper.findComponent(GlIcon);
      environmentName = wrapper.findByText(resolvedEnvironment.name);
    });

    it('is collapsed by default', () => {
      expect(collapse.attributes('visible')).toBeUndefined();
      expect(icon.props('name')).toBe('chevron-lg-right');
      expect(environmentName.classes('gl-font-weight-bold')).toBe(false);
    });

    it('opens on click', async () => {
      expect(findDeployment().isVisible()).toBe(false);

      const button = await expandCollapsedSection();

      expect(button.attributes('aria-label')).toBe(__('Collapse'));
      expect(button.props('category')).toBe('secondary');
      expect(collapse.attributes('visible')).toBe('visible');
      expect(icon.props('name')).toBe('chevron-lg-down');
      expect(environmentName.classes('gl-font-weight-bold')).toBe(true);
      expect(findDeployment().isVisible()).toBe(true);
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
      expect(deployment.props('deployment')).toEqual(upcomingDeployment);
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
    it('should link to documentation', async () => {
      const environment = {
        ...resolvedEnvironment,
        lastDeployment: null,
        upcomingDeployment: null,
      };

      wrapper = createWrapper({
        propsData: { environment },
        apolloProvider: createApolloProvider(),
      });

      await expandCollapsedSection();

      const text = s__(
        'Environments|There are no deployments for this environment yet. Learn more about setting up deployments.',
      );

      const emptyState = wrapper.findByText((_content, element) => element.textContent === text);

      const link = extendedWrapper(emptyState).findByRole('link');

      expect(link.attributes('href')).toBe('/help');
    });

    it('should not link to the documentation when there are deployments', async () => {
      wrapper = createWrapper({
        apolloProvider: createApolloProvider(),
      });

      await expandCollapsedSection();

      const text = s__(
        'Environments|There are no deployments for this environment yet. Learn more about setting up deployments.',
      );

      const emptyState = wrapper.findByText((_content, element) => element.textContent === text);

      expect(emptyState.exists()).toBe(false);
    });
  });

  describe('deploy boards', () => {
    it('should show a deploy board if the environment has a rollout status', async () => {
      const environment = {
        ...resolvedEnvironment,
        rolloutStatus,
      };

      wrapper = createWrapper({
        propsData: { environment },
        apolloProvider: createApolloProvider(),
      });

      await expandCollapsedSection();

      const deployBoard = wrapper.findComponent(DeployBoardWrapper);
      expect(deployBoard.exists()).toBe(true);
      expect(deployBoard.props('rolloutStatus')).toBe(rolloutStatus);
    });

    it('should not show a deploy board if the environment has no rollout status', async () => {
      wrapper = createWrapper({
        apolloProvider: createApolloProvider(),
      });

      await expandCollapsedSection();

      const deployBoard = wrapper.findComponent(DeployBoardWrapper);
      expect(deployBoard.exists()).toBe(false);
    });
  });

  describe('kubernetes overview', () => {
    const environmentWithAgent = {
      ...resolvedEnvironment,
      agent,
    };

    it('should render if the feature flag is enabled and the environment has an agent object with the required data specified', () => {
      wrapper = createWrapper({
        propsData: { environment: environmentWithAgent },
        provideData: {
          glFeatures: {
            kasUserAccessProject: true,
          },
        },
        apolloProvider: createApolloProvider(),
      });

      expandCollapsedSection();

      expect(findKubernetesOverview().props()).toMatchObject({
        agentProjectPath: agent.project,
        agentName: agent.name,
        agentId: agent.id,
        namespace: agent.kubernetesNamespace,
      });
    });

    it('should not render if the feature flag is not enabled', () => {
      wrapper = createWrapper({
        propsData: { environment: environmentWithAgent },
        apolloProvider: createApolloProvider(),
      });

      expandCollapsedSection();

      expect(findKubernetesOverview().exists()).toBe(false);
    });

    it('should not render if the environment has no agent object', () => {
      wrapper = createWrapper({
        apolloProvider: createApolloProvider(),
      });

      expandCollapsedSection();

      expect(findKubernetesOverview().exists()).toBe(false);
    });

    it('should not render if the environment has an agent object without agent id specified', () => {
      const environment = {
        ...resolvedEnvironment,
        agent: {
          project: agent.project,
          name: agent.name,
        },
      };

      wrapper = createWrapper({
        propsData: { environment },
        apolloProvider: createApolloProvider(),
      });

      expandCollapsedSection();

      expect(findKubernetesOverview().exists()).toBe(false);
    });
  });
});
