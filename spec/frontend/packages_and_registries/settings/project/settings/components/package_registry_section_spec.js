import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import PackageRegistrySection from '~/packages_and_registries/settings/project/components/package_registry_section.vue';
import PackagesCleanupPolicy from '~/packages_and_registries/settings/project/components/packages_cleanup_policy.vue';
import PackagesProtectionRules from '~/packages_and_registries/settings/project/components/packages_protection_rules.vue';
import DependencyProxyPackagesSettings from 'ee_component/packages_and_registries/settings/project/components/dependency_proxy_packages_settings.vue';

describe('Package registry project settings section', () => {
  let wrapper;

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findLink = () => findSettingsBlock().findComponent(GlLink);
  const findPackagesCleanupPolicy = () => wrapper.findComponent(PackagesCleanupPolicy);
  const findPackagesProtectionRules = () => wrapper.findComponent(PackagesProtectionRules);
  const findDependencyProxyPackagesSettings = () =>
    wrapper.findComponent(DependencyProxyPackagesSettings);

  const defaultProvide = {
    showDependencyProxySettings: false,
  };

  const mountComponent = (provide = {}) => {
    wrapper = shallowMount(PackageRegistrySection, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  describe('settings', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders with title', () => {
      expect(findSettingsBlock().props('title')).toBe('Package registry');
    });

    it('renders with description', () => {
      expect(findSettingsBlock().text()).toBe(
        'With the GitLab package registry, you can use GitLab as a private or public registry for a variety of supported package managers. You can publish and share packages, which can be consumed as a dependency in downstream projects.',
      );
    });

    it('renders the help page link with correct href', () => {
      const link = findLink();
      const docsPath = helpPagePath('user/packages/package_registry/supported_package_managers.md');

      expect(link.attributes('href')).toBe(docsPath);
    });

    it('renders package cleanup policy & protection rules', () => {
      mountComponent();

      expect(findPackagesCleanupPolicy().exists()).toBe(true);
      expect(findPackagesProtectionRules().exists()).toBe(true);
    });

    it.each([true, false])('when showDependencyProxySettings is %s', (value) => {
      mountComponent({
        showDependencyProxySettings: value,
      });

      expect(findDependencyProxyPackagesSettings().exists()).toBe(value);
    });
  });
});
