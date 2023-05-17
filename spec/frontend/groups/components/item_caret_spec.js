import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ItemCaret from '~/groups/components/item_caret.vue';

describe('ItemCaret', () => {
  let wrapper;

  const defaultProps = {
    isGroupOpen: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ItemCaret, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findAllGlIcons = () => wrapper.findAllComponents(GlIcon);
  const findGlIcon = () => wrapper.findComponent(GlIcon);

  describe('template', () => {
    it('renders component template correctly', () => {
      createComponent();

      expect(wrapper.classes()).toContain('folder-caret');
      expect(findAllGlIcons()).toHaveLength(1);
    });

    it.each`
      isGroupOpen | icon
      ${true}     | ${'chevron-down'}
      ${false}    | ${'chevron-right'}
    `('renders "$icon" icon when `isGroupOpen` is $isGroupOpen', ({ isGroupOpen, icon }) => {
      createComponent({
        isGroupOpen,
      });

      expect(findGlIcon().props('name')).toBe(icon);
    });
  });
});
