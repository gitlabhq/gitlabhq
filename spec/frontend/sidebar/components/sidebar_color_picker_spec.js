import { GlFormGroup, GlFormInput, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SibebarColorPicker from '~/sidebar/components/sidebar_color_picker.vue';
import { mockSuggestedEpicColors } from './mock_data';

describe('SibebarColorPicker', () => {
  let wrapper;
  const findAllColors = () => wrapper.findAllComponents(GlLink);
  const findFirstColor = () => findAllColors().at(0);
  const findColorPicker = () => wrapper.findAllComponents(GlFormInput).at(0);
  const findColorPickerText = () => wrapper.findAllComponents(GlFormInput).at(1);
  const findColorPickerTextFormGroup = () => wrapper.findAllComponents(GlFormGroup).at(1);

  const createComponent = ({
    value = '',
    suggestedColors = mockSuggestedEpicColors,
    errorMessage = '',
    autofocus = false,
  } = {}) => {
    wrapper = shallowMountExtended(SibebarColorPicker, {
      propsData: {
        value,
        autofocus,
        suggestedColors,
        errorMessage,
      },
    });
  };

  it('renders a palette of 14 colors', () => {
    createComponent();
    expect(findAllColors()).toHaveLength(14);
  });

  it('renders value of the color in textbox', () => {
    createComponent({ value: '#343434' });
    expect(findColorPickerText().attributes('value')).toBe('#343434');
  });

  it('sets autofocus attribute if the prop is passed as true', () => {
    createComponent({ autofocus: true });

    expect(findColorPickerText().attributes('autofocus')).toBe('true');
  });

  describe('color picker', () => {
    beforeEach(() => {
      createComponent();
    });

    it('emits color on click of suggested color link', () => {
      findFirstColor().vm.$emit('click', new Event('mouseclick'));

      expect(wrapper.emitted('input')).toEqual([['#E9BE74']]);
    });

    it('emits color on selecting color from picker', () => {
      findColorPicker().vm.$emit('input', '#ffffff');

      expect(wrapper.emitted('input')).toEqual([['#ffffff']]);
    });

    it('emits color on typing the hex code in the input', () => {
      findColorPickerText().vm.$emit('input', '#000000');

      expect(wrapper.emitted('input')).toEqual([['#000000']]);
    });

    it('sets invalid state if error message is provided', () => {
      createComponent({ errorMessage: 'Invalid hex' });

      expect(findColorPickerTextFormGroup().attributes('invalid-feedback')).toBe('Invalid hex');
    });
  });
});
