import { GlDropdownForm } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DropdownContentsColorView from '~/vue_shared/components/color_select_dropdown/dropdown_contents_color_view.vue';
import ColorItem from '~/vue_shared/components/color_select_dropdown/color_item.vue';
import { ISSUABLE_COLORS } from '~/vue_shared/components/color_select_dropdown/constants';
import { color as defaultColor } from './mock_data';

const propsData = {
  selectedColor: defaultColor,
};

describe('DropdownContentsColorView', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(DropdownContentsColorView, {
      propsData,
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findColors = () => wrapper.findAllComponents(ColorItem);
  const findColorList = () => wrapper.findComponent(GlDropdownForm);

  it('renders color list', () => {
    expect(findColorList().exists()).toBe(true);
    expect(findColors()).toHaveLength(ISSUABLE_COLORS.length);
  });

  it.each(ISSUABLE_COLORS)('emits an `input` event with %o on click on the option %#', (color) => {
    const colorIndex = ISSUABLE_COLORS.indexOf(color);
    findColors().at(colorIndex).trigger('click');

    expect(wrapper.emitted('input')[0][0]).toMatchObject(color);
  });
});
