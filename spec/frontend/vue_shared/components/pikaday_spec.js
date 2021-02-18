import { GlDatepicker } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import datePicker from '~/vue_shared/components/pikaday.vue';

describe('datePicker', () => {
  let wrapper;

  const buildWrapper = (propsData = {}) => {
    wrapper = shallowMount(datePicker, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });
  it('should emit newDateSelected when GlDatePicker emits the input event', () => {
    const minDate = new Date();
    const maxDate = new Date();
    const selectedDate = new Date();
    const theDate = selectedDate.toISOString().slice(0, 10);

    buildWrapper({ minDate, maxDate, selectedDate });

    expect(wrapper.find(GlDatepicker).props()).toMatchObject({
      minDate,
      maxDate,
      value: selectedDate,
    });
    wrapper.find(GlDatepicker).vm.$emit('input', selectedDate);
    expect(wrapper.emitted('newDateSelected')[0][0]).toBe(theDate);
  });
  it('should emit the hidePicker event when GlDatePicker emits the close event', () => {
    buildWrapper();

    wrapper.find(GlDatepicker).vm.$emit('close');

    expect(wrapper.emitted('hidePicker')).toHaveLength(1);
  });
});
