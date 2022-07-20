import { shallowMount } from '@vue/test-utils';
import component from '~/packages_and_registries/settings/project/components/registry_settings_app.vue';
import ContainerExpirationPolicy from '~/packages_and_registries/settings/project/components/container_expiration_policy.vue';
import PackagesCleanupPolicy from '~/packages_and_registries/settings/project/components/packages_cleanup_policy.vue';

describe('Registry Settings app', () => {
  let wrapper;

  const findContainerExpirationPolicy = () => wrapper.find(ContainerExpirationPolicy);
  const findPackagesCleanupPolicy = () => wrapper.find(PackagesCleanupPolicy);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const mountComponent = (provide) => {
    wrapper = shallowMount(component, {
      provide,
    });
  };

  it.each`
    showContainerRegistrySettings | showPackageRegistrySettings
    ${true}                       | ${false}
    ${true}                       | ${true}
    ${false}                      | ${true}
    ${false}                      | ${false}
  `(
    'container expiration policy $showContainerRegistrySettings and package cleanup policy is $showPackageRegistrySettings',
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
