import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as commonUtils from '~/lib/utils/common_utils';
import component from '~/packages_and_registries/settings/project/components/registry_settings_app.vue';
import ContainerExpirationPolicy from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';
import ContainerProtectionRules from '~/packages_and_registries/settings/project/components/container_protection_rules.vue';
import PackagesCleanupPolicy from '~/packages_and_registries/settings/project/components/packages_cleanup_policy.vue';
import PackagesProtectionRules from '~/packages_and_registries/settings/project/components/packages_protection_rules.vue';
import DependencyProxyPackagesSettings from 'ee_component/packages_and_registries/settings/project/components/dependency_proxy_packages_settings.vue';
import MetadataDatabaseAlert from '~/packages_and_registries/shared/components/container_registry_metadata_database_alert.vue';
import PackageRegistrySection from '~/packages_and_registries/settings/project/components/package_registry_section.vue';
import ContainerRegistrySection from '~/packages_and_registries/settings/project/components/container_registry_section.vue';
import {
  SHOW_SETUP_SUCCESS_ALERT,
  UPDATE_SETTINGS_SUCCESS_MESSAGE,
} from '~/packages_and_registries/settings/project/constants';

jest.mock('~/lib/utils/common_utils');

describe('Registry Settings app', () => {
  let wrapper;

  const findContainerExpirationPolicy = () => wrapper.findComponent(ContainerExpirationPolicy);
  const findContainerProtectionRules = () => wrapper.findComponent(ContainerProtectionRules);
  const findPackagesCleanupPolicy = () => wrapper.findComponent(PackagesCleanupPolicy);
  const findPackagesProtectionRules = () => wrapper.findComponent(PackagesProtectionRules);
  const findDependencyProxyPackagesSettings = () =>
    wrapper.findComponent(DependencyProxyPackagesSettings);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findMetadataDatabaseAlert = () => wrapper.findComponent(MetadataDatabaseAlert);
  const findContainerRegistrySection = () => wrapper.findComponent(ContainerRegistrySection);
  const findPackageRegistrySection = () => wrapper.findComponent(PackageRegistrySection);

  const defaultProvide = {
    showContainerRegistrySettings: true,
    showPackageRegistrySettings: true,
    showDependencyProxySettings: false,
    glFeatures: {
      containerRegistryProtectedContainers: true,
      reorganizeProjectLevelRegistrySettings: false,
    },
    isContainerRegistryMetadataDatabaseEnabled: false,
  };

  const mountComponent = (provide = defaultProvide) => {
    wrapper = shallowMount(component, {
      provide,
    });
  };

  describe('metadata database alert', () => {
    it('is rendered when metadata database is not enabled', () => {
      mountComponent();

      expect(findMetadataDatabaseAlert().exists()).toBe(true);
    });

    it('is not rendered when metadata database is enabled', () => {
      mountComponent({
        ...defaultProvide,
        isContainerRegistryMetadataDatabaseEnabled: true,
      });

      expect(findMetadataDatabaseAlert().exists()).toBe(false);
    });
  });

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
          ...defaultProvide,
          showContainerRegistrySettings,
          showPackageRegistrySettings,
        });

        expect(findContainerExpirationPolicy().exists()).toBe(showContainerRegistrySettings);
        expect(findContainerProtectionRules().exists()).toBe(showContainerRegistrySettings);
        expect(findPackagesCleanupPolicy().exists()).toBe(showPackageRegistrySettings);
        expect(findPackagesProtectionRules().exists()).toBe(showPackageRegistrySettings);
      },
    );

    it.each([true, false])('when showDependencyProxySettings is %s', (value) => {
      mountComponent({
        ...defaultProvide,
        showDependencyProxySettings: value,
      });

      expect(findDependencyProxyPackagesSettings().exists()).toBe(value);
    });

    describe('when feature flag "containerRegistryProtectedContainers" is disabled', () => {
      it.each([true, false])(
        'container protection rules settings is hidden if showContainerRegistrySettings is %s',
        (showContainerRegistrySettings) => {
          mountComponent({
            ...defaultProvide,
            showContainerRegistrySettings,
            glFeatures: { containerRegistryProtectedContainers: false },
          });

          expect(findContainerProtectionRules().exists()).toBe(false);
        },
      );
    });
  });

  describe('when feature flag "reorganizeProjectLevelRegistrySettings" is enabled', () => {
    it('does not show existing sections', () => {
      mountComponent({
        ...defaultProvide,
        glFeatures: { reorganizeProjectLevelRegistrySettings: true },
      });

      expect(findContainerExpirationPolicy().exists()).toBe(false);
      expect(findContainerProtectionRules().exists()).toBe(false);
      expect(findPackagesCleanupPolicy().exists()).toBe(false);
      expect(findPackagesProtectionRules().exists()).toBe(false);
      expect(findDependencyProxyPackagesSettings().exists()).toBe(false);
    });

    it.each`
      showContainerRegistrySettings | showPackageRegistrySettings
      ${true}                       | ${false}
      ${true}                       | ${true}
      ${false}                      | ${true}
      ${false}                      | ${false}
    `(
      'container registry section $showContainerRegistrySettings and package registry section is $showPackageRegistrySettings',
      ({ showContainerRegistrySettings, showPackageRegistrySettings }) => {
        mountComponent({
          ...defaultProvide,
          showContainerRegistrySettings,
          showPackageRegistrySettings,
          glFeatures: { reorganizeProjectLevelRegistrySettings: true },
        });

        expect(findContainerRegistrySection().exists()).toBe(showContainerRegistrySettings);
        expect(findPackageRegistrySection().exists()).toBe(showPackageRegistrySettings);
      },
    );
  });
});
