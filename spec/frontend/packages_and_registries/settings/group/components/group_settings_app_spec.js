import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';

import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import PackagesSettings from '~/packages_and_registries/settings/group/components/packages_settings.vue';
import DependencyProxySettings from '~/packages_and_registries/settings/group/components/dependency_proxy_settings.vue';
import PackagesForwardingSettings from '~/packages_and_registries/settings/group/components/packages_forwarding_settings.vue';

import component from '~/packages_and_registries/settings/group/components/group_settings_app.vue';

import getGroupPackagesSettingsQuery from '~/packages_and_registries/settings/group/graphql/queries/get_group_packages_settings.query.graphql';
import {
  groupPackageSettingsMock,
  packageSettings,
  dependencyProxySettings,
  dependencyProxyImageTtlPolicy,
} from '../mock_data';

jest.mock('~/alert');

describe('Group Settings App', () => {
  let wrapper;
  let apolloProvider;
  let show;

  const defaultProvide = {
    groupPath: 'foo_group_path',
  };

  const mountComponent = ({
    resolver = jest.fn().mockResolvedValue(groupPackageSettingsMock),
    provide = defaultProvide,
  } = {}) => {
    Vue.use(VueApollo);

    const requestHandlers = [[getGroupPackagesSettingsQuery, resolver]];

    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(component, {
      apolloProvider,
      provide,
      mocks: {
        $toast: {
          show,
        },
      },
    });
  };

  beforeEach(() => {
    show = jest.fn();
  });

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findPackageSettings = () => wrapper.findComponent(PackagesSettings);
  const findPackageForwardingSettings = () => wrapper.findComponent(PackagesForwardingSettings);
  const findDependencyProxySettings = () => wrapper.findComponent(DependencyProxySettings);

  const waitForApolloQueryAndRender = async () => {
    await waitForPromises();
    await nextTick();
  };

  const packageSettingsProps = { packageSettings };
  const packageForwardingSettingsProps = { forwardSettings: { ...packageSettings } };
  const dependencyProxyProps = {
    dependencyProxySettings: dependencyProxySettings(),
    dependencyProxyImageTtlPolicy: dependencyProxyImageTtlPolicy(),
  };

  describe.each`
    finder                           | entitySpecificProps               | id
    ${findPackageSettings}           | ${packageSettingsProps}           | ${'packages-settings'}
    ${findPackageForwardingSettings} | ${packageForwardingSettingsProps} | ${'packages-forwarding-settings'}
    ${findDependencyProxySettings}   | ${dependencyProxyProps}           | ${'dependency-proxy-settings'}
  `('settings blocks', ({ finder, entitySpecificProps, id }) => {
    beforeEach(() => {
      mountComponent();
      return waitForApolloQueryAndRender();
    });

    it('renders the settings block', () => {
      expect(finder().exists()).toBe(true);
    });

    it('has the correct id', () => {
      expect(finder().attributes('id')).toBe(id);
    });

    it('binds the correctProps', () => {
      expect(finder().props()).toMatchObject(entitySpecificProps);
    });

    describe('success event', () => {
      it('shows a success toast', () => {
        finder().vm.$emit('success');
        expect(show).toHaveBeenCalledWith('Settings saved successfully.');
      });

      it('hides the error alert', async () => {
        finder().vm.$emit('error');
        await nextTick();

        expect(findAlert().exists()).toBe(true);

        finder().vm.$emit('success');
        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });

    describe('error event', () => {
      beforeEach(() => {
        finder().vm.$emit('error');
        return nextTick();
      });

      it('shows an alert', () => {
        expect(findAlert().exists()).toBe(true);
      });

      it('alert has the right text', () => {
        expect(findAlert().text()).toBe('An error occurred while saving the settings.');
      });

      it('dismissing the alert removes it', async () => {
        expect(findAlert().exists()).toBe(true);

        findAlert().vm.$emit('dismiss');

        await nextTick();

        expect(findAlert().exists()).toBe(false);
      });
    });
  });
});
