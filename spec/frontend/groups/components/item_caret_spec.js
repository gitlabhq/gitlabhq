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

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findAllGlIcons = () => wrapper.findAll(GlIcon);
  const findGlIcon = () => wrapper.find(GlIcon);

  describe('template', () => {
    it('renders component template correctly', () => {
      createComponent();

      expect(wrapper.classes()).toContain('folder-caret');
      expect(findAllGlIcons()).toHaveLength(1);
    });

    it.each`
      isGroupOpen | icon
      ${true}     | ${'angle-down'}
      ${false}    | ${'angle-right'}
    `('renders "$icon" icon when `isGroupOpen` is $isGroupOpen', ({ isGroupOpen, icon }) => {
      createComponent({
        isGroupOpen,
      });

      expect(findGlIcon().props('name')).toBe(icon);
    });
  });
});
