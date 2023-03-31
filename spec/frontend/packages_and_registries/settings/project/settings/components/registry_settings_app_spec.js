import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as commonUtils from '~/lib/utils/common_utils';
import component from '~/packages_and_registries/settings/project/components/registry_settings_app.vue';
import ContainerExpirationPolicy from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';
import PackagesCleanupPolicy from '~/packages_and_registries/settings/project/components/packages_cleanup_policy.vue';
import {
  SHOW_SETUP_SUCCESS_ALERT,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/packages_and_registries/settings/project/constants';

jest.mock('~/lib/utils/common_utils');

describe('Registry Settings app', () => {
  let wrapper;

  const findContainerExpirationPolicy = () => wrapper.findComponent(ContainerExpirationPolicy);
  const findPackagesCleanupPolicy = () => wrapper.findComponent(PackagesCleanupPolicy);
  const findAlert = () => wrapper.findComponent(GlAlert);

  const defaultProvide = {
    showContainerRegistrySettings: true,
    showPackageRegistrySettings: true,
  };

  const mountComponent = (provide = defaultProvide) => {
    wrapper = shallowMount(component, {
      provide,
    });
  };

  describe('container policy success alert handling', () => {
    const originalLocation = window.location.href;
    const search = `?${SHOW_SETUP_SUCCESS_ALERT}=true`;

    beforeEach(() => {
      setWindowLocation(search);
    });

    afterEach(() => {
      setWindowLocation(originalLocation);
    });

    it(`renders alert if the query string contains ${SHOW_SETUP_SUCCESS_ALERT}`, async () => {
      mountComponent();

      await waitForPromises();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().props()).toMatchObject({
        dismissible: true,
        variant: 'success',
      });
      expect(findAlert().text()).toMatchInterpolatedText(UPDATE_SETTINGS_SUCCESS_MESSAGE);
    });

    it('calls historyReplaceState with a clean url', () => {
      mountComponent();

      expect(commonUtils.historyReplaceState).toHaveBeenCalledWith(originalLocation);
    });

    it(`does nothing if the query string does not contain ${SHOW_SETUP_SUCCESS_ALERT}`, () => {
      setWindowLocation('?');
      mountComponent();

      expect(findAlert().exists()).toBe(false);
      expect(commonUtils.historyReplaceState).not.toHaveBeenCalled();
    });
  });

  describe('settings', () => {
    it.each`
      showContainerRegistrySettings | showPackageRegistrySettings
      ${true}                       | ${false}
      ${true}                       | ${true}
      ${false}                      | ${true}
      ${false}                      | ${false}
    `(
      'container cleanup policy $showContainerRegistrySettings and package cleanup policy is $showPackageRegistrySettings',
      ({ showContainerRegistrySettings, showPackageRegistrySettings }) => {
        mountComponent({
          showContainerRegistrySettings,
          showPackageRegistrySettings,
        });

        expect(findContainerExpirationPolicy().exists()).toBe(showContainerRegistrySettings);
        expect(findPackagesCleanupPolicy().exists()).toBe(showPackageRegistrySettings);
      },
    );
  });
});
