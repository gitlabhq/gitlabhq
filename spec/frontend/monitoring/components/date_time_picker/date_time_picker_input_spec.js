import { mount } from '@vue/test-utils';
import DateTimePickerInput from '~/monitoring/components/date_time_picker/date_time_picker_input.vue';

const inputLabel = 'This is a label';
const inputValue = 'something';

describe('DateTimePickerInput', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mount(DateTimePickerInput, {
      propsData: {
        state: null,
        value: '',
        label: '',
        ...propsData,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders label above the input', () => {
    createComponent({
      label: inputLabel,
    });

    expect(wrapper.find('.gl-form-group label').text()).toBe(inputLabel);
  });

  it('renders the same `ID` for input and `for` for label', () => {
    createComponent({ label: inputLabel });

    expect(wrapper.find('.gl-form-group label').attributes('for')).toBe(
      wrapper.find('input').attributes('id'),
    );
  });

  it('renders valid input in gray color instead of green', () => {
    createComponent({
      state: true,
    });

    expect(wrapper.find('input').classes('is-valid')).toBe(false);
  });

  it('renders invalid input in red color', () => {
    createComponent({
      state: false,
    });

    expect(wrapper.find('input').classes('is-invalid')).toBe(true);
  });

  it('input event is emitted when focus is lost', () => {
    createComponent();
    jest.spyOn(wrapper.vm, '$emit');
    const input = wrapper.find('input');
    input.setValue(inputValue);
    input.trigger('blur');

    expect(wrapper.vm.$emit).toHaveBeenCalledWith('input', inputValue);
  });
});
