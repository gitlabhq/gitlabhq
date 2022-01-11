import VueApollo from 'vue-apollo';
import Vue from 'vue';
import { GlCollapse, GlIcon } from '@gitlab/ui';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubTransition } from 'helpers/stub_transition';
import { __, s__ } from '~/locale';
import EnvironmentItem from '~/environments/components/new_environment_item.vue';
import { resolvedEnvironment } from './graphql/mock_data';

Vue.use(VueApollo);

describe('~/environments/components/new_environment_item.vue', () => {
  let wrapper;

  const createApolloProvider = () => {
    return createMockApollo();
  };

  const createWrapper = ({ propsData = {}, apolloProvider } = {}) =>
    mountExtended(EnvironmentItem, {
      apolloProvider,
      propsData: { environment: resolvedEnvironment, ...propsData },
      stubs: { transition: stubTransition() },
    });

  afterEach(() => {
    wrapper?.destroy();
  });

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

      const actions = wrapper.findByRole('button', { name: __('Deploy to...') });

      expect(actions.exists()).toBe(true);
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

      const actions = wrapper.findByRole('button', { name: __('Deploy to...') });

      expect(actions.exists()).toBe(false);
    });

    it('passes all the actions down to the action component', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const action = wrapper.findByRole('menuitem', { name: 'deploy-staging' });

      expect(action.exists()).toBe(true);
    });
  });

  describe('stop', () => {
    it('shows a buton to stop the environment if the environment is available', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const stop = wrapper.findByRole('button', { name: s__('Environments|Stop environment') });

      expect(stop.exists()).toBe(true);
    });

    it('does not show a buton to stop the environment if the environment is stopped', () => {
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
    it('shows the option to pin the environment if there is an autostop date', () => {
      wrapper = createWrapper({
        propsData: {
          environment: { ...resolvedEnvironment, autoStopAt: new Date(Date.now() + 100000) },
        },
        apolloProvider: createApolloProvider(),
      });

      const rollback = wrapper.findByRole('menuitem', { name: __('Prevent auto-stopping') });

      expect(rollback.exists()).toBe(true);
    });

    it('does not show the option to pin the environment if there is no autostop date', () => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });

      const rollback = wrapper.findByRole('menuitem', { name: __('Prevent auto-stopping') });

      expect(rollback.exists()).toBe(false);
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
    let button;
    let environmentName;

    beforeEach(() => {
      wrapper = createWrapper({ apolloProvider: createApolloProvider() });
      collapse = wrapper.findComponent(GlCollapse);
      icon = wrapper.findComponent(GlIcon);
      button = wrapper.findByRole('button', { name: __('Expand') });
      environmentName = wrapper.findByText(resolvedEnvironment.name);
    });

    it('is collapsed by default', () => {
      expect(collapse.attributes('visible')).toBeUndefined();
      expect(icon.props('name')).toEqual('angle-right');
      expect(environmentName.classes('gl-font-weight-bold')).toBe(false);
    });

    it('opens on click', async () => {
      await button.trigger('click');

      expect(button.attributes('aria-label')).toBe(__('Collapse'));
      expect(collapse.attributes('visible')).toBe('visible');
      expect(icon.props('name')).toEqual('angle-down');
      expect(environmentName.classes('gl-font-weight-bold')).toBe(true);
    });
  });
});
