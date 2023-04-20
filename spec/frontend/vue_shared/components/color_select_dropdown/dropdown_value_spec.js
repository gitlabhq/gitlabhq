import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import ColorItem from '~/vue_shared/components/color_select_dropdown/color_item.vue';
import DropdownValue from '~/vue_shared/components/color_select_dropdown/dropdown_value.vue';

import { color } from './mock_data';

const propsData = {
  selectedColor: color,
};

describe('DropdownValue', () => {
  let wrapper;

  const findColorItems = () => wrapper.findAllComponents(ColorItem);

  const createComponent = () => {
    wrapper = shallowMountExtended(DropdownValue, { propsData });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when there is a color set', () => {
    it('renders the color', () => {
      expect(findColorItems()).toHaveLength(2);
    });

    it.each`
      index | cssClass
      ${0}  | ${[]}
      ${1}  | ${['hide-collapsed']}
    `('passes correct props to the ColorItem with CSS class `$cssClass`', ({ index, cssClass }) => {
      expect(findColorItems().at(index).props()).toMatchObject(propsData.selectedColor);
      expect(findColorItems().at(index).classes()).toEqual(cssClass);
    });
  });
});
