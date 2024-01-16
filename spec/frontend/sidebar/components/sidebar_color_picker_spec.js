import { GlFormInput, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SibebarColorPicker from '~/sidebar/components/sidebar_color_picker.vue';
import { mockSuggestedColors } from './mock_data';

describe('SibebarColorPicker', () => {
  let wrapper;
  const findAllColors = () => wrapper.findAllComponents(GlLink);
  const findFirstColor = () => findAllColors().at(0);
  const findColorPicker = () => wrapper.findComponent(GlFormInput);
  const findColorPickerText = () => wrapper.findByTestId('selected-color-text');

  const createComponent = ({ value = '' } = {}) => {
    wrapper = shallowMountExtended(SibebarColorPicker, {
      propsData: {
        value,
      },
    });
  };

  beforeEach(() => {
    gon.suggested_label_colors = mockSuggestedColors;
  });

  it('renders a palette of 21 colors', () => {
    createComponent();
    expect(findAllColors()).toHaveLength(21);
  });

  it('renders value of the color in textbox', () => {
    createComponent({ value: '#343434' });
    expect(findColorPickerText().attributes('value')).toBe('#343434');
  });

  describe('color picker', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits color on click of suggested color link', () => {
      findFirstColor().vm.$emit('click', new Event('mouseclick'));

      expect(wrapper.emitted('input')).toEqual([['#009966']]);
    });

    it('emits color on selecting color from picker', () => {
      findColorPicker().vm.$emit('input', '#ffffff');

      expect(wrapper.emitted('input')).toEqual([['#ffffff']]);
    });

    it('emits color on typing the hex code in the input', () => {
      findColorPickerText().vm.$emit('input', '#000000');

      expect(wrapper.emitted('input')).toEqual([['#000000']]);
    });
  });
});
