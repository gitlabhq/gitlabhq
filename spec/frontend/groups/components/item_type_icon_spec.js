import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import ItemTypeIcon from '~/groups/components/item_type_icon.vue';
import { ITEM_TYPE } from '../mock_data';

describe('ItemTypeIcon', () => {
  let wrapper;

  const defaultProps = {
    itemType: ITEM_TYPE.GROUP,
    isGroupOpen: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ItemTypeIcon, {
      propsData: { ...defaultProps, ...props },
    });
  };

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  const findGlIcon = () => wrapper.find(GlIcon);

  describe('template', () => {
    it('renders component template correctly', () => {
      createComponent();

      expect(wrapper.classes()).toContain('item-type-icon');
    });

    it.each`
      type                 | isGroupOpen | icon
      ${ITEM_TYPE.GROUP}   | ${true}     | ${'folder-open'}
      ${ITEM_TYPE.GROUP}   | ${false}    | ${'folder-o'}
      ${ITEM_TYPE.PROJECT} | ${true}     | ${'bookmark'}
      ${ITEM_TYPE.PROJECT} | ${false}    | ${'bookmark'}
    `(
      'shows "$icon" icon when `itemType` is "$type" and `isGroupOpen` is $isGroupOpen',
      ({ type, isGroupOpen, icon }) => {
        createComponent({
          itemType: type,
          isGroupOpen,
        });
        expect(findGlIcon().props('name')).toBe(icon);
      },
    );
  });
});
