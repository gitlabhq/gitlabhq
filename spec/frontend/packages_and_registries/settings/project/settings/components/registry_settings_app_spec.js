import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as commonUtils from '~/lib/utils/common_utils';
import RegistrySettingsApp from '~/packages_and_registries/settings/project/components/registry_settings_app.vue';
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

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findMetadataDatabaseAlert = () => wrapper.findComponent(MetadataDatabaseAlert);
  const findContainerRegistrySection = () => wrapper.findComponent(ContainerRegistrySection);
  const findPackageRegistrySection = () => wrapper.findComponent(PackageRegistrySection);

  const defaultProvide = {
    showContainerRegistrySettings: true,
    showPackageRegistrySettings: true,
    isContainerRegistryMetadataDatabaseEnabled: false,
  };

  const mountComponent = (provide = defaultProvide) => {
    wrapper = shallowMount(RegistrySettingsApp, {
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

      expect(findContainerRegistrySection().props('expanded')).toBe(true);
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
      expect(findContainerRegistrySection().props('expanded')).toBe(false);
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
      'container registry section $showContainerRegistrySettings and package registry section is $showPackageRegistrySettings',
      ({ showContainerRegistrySettings, showPackageRegistrySettings }) => {
        mountComponent({
          ...defaultProvide,
          showContainerRegistrySettings,
          showPackageRegistrySettings,
        });

        expect(findContainerRegistrySection().exists()).toBe(showContainerRegistrySettings);
        expect(findPackageRegistrySection().exists()).toBe(showPackageRegistrySettings);
      },
    );
  });
});
