import { rgbFromHex } from '@gitlab/ui/dist/utils/utils';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ColorItem from '~/vue_shared/components/color_select_dropdown/color_item.vue';
import { color } from './mock_data';

describe('ColorItem', () => {
  let wrapper;

  const propsData = color;

  const createComponent = () => {
    wrapper = shallowMountExtended(ColorItem, {
      propsData,
    });
  };

  const findColorItem = () => wrapper.findByTestId('color-item');

  beforeEach(() => {
    createComponent();
  });

  it('renders the correct title', () => {
    expect(wrapper.text()).toBe(propsData.title);
  });

  it('renders the correct background color for the color item', () => {
    const colorAsRGB = rgbFromHex(propsData.color);
    expect(findColorItem().attributes('style')).toBe(
      `background-color: rgb(${colorAsRGB.join(', ')});`,
    );
  });
});
