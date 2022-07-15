import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ResourceLinksBlock from '~/linked_resources/components/resource_links_block.vue';

describe('ResourceLinksBlock', () => {
  let wrapper;

  const findResourceLinkAddButton = () => wrapper.find(GlButton);
  const helpPath = '/help/user/project/issues/linked_resources';

  describe('with defaults', () => {
    it('renders correct component', () => {
      wrapper = shallowMount(ResourceLinksBlock, {
        propsData: {
          helpPath,
          canAddResourceLinks: true,
        },
      });

      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('with canAddResourceLinks=false', () => {
    it('does not show the add button', () => {
      wrapper = shallowMount(ResourceLinksBlock, {
        propsData: {
          canAddResourceLinks: false,
        },
      });

      expect(findResourceLinkAddButton().exists()).toBe(false);
    });
  });
});
