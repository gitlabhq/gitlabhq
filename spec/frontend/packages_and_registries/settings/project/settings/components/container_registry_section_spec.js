import { GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import ContainerRegistrySection from '~/packages_and_registries/settings/project/components/container_registry_section.vue';
import { helpPagePath } from '~/helpers/help_page_helper';

describe('Container registry project settings section', () => {
  let wrapper;

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);
  const findLink = () => findSettingsBlock().findComponent(GlLink);

  const mountComponent = () => {
    wrapper = shallowMount(ContainerRegistrySection, {
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
      expect(findSettingsBlock().props('title')).toBe('Container registry');
    });

    it('renders with description', () => {
      expect(findSettingsBlock().text()).toBe(
        'The GitLab Container Registry is a secure and private registry for container images. It’s built on open source software and completely integrated within GitLab. Use GitLab CI/CD to create and publish images. Use the GitLab API to manage the registry across groups and projects.',
      );
    });

    it('renders the help page link with correct href', () => {
      const link = findLink();
      const docsPath = helpPagePath('/user/packages/container_registry/index.md');

      expect(link.attributes('href')).toBe(docsPath);
    });
  });
});
