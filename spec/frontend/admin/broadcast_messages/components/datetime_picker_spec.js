import { mount } from '@vue/test-utils';
import { GlDatepicker } from '@gitlab/ui';
import DatetimePicker from '~/admin/broadcast_messages/components/datetime_picker.vue';

describe('DatetimePicker', () => {
  let wrapper;

  const toDate = (day, time) => new Date(`${day}T${time}:00.000Z`);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findTimepicker = () => wrapper.findComponent('[data-testid="time-picker"]');

  const testDay = '2022-03-22';
  const testTime = '01:23';

  function createComponent() {
    wrapper = mount(DatetimePicker, {
      propsData: {
        value: toDate(testDay, testTime),
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  it('renders the Date in the datepicker and timepicker inputs', () => {
    expect(findDatepicker().props().value).toEqual(toDate(testDay, testTime));
    expect(findTimepicker().element.value).toEqual(testTime);
  });

  it('emits Date with the new day/old time when the date picker changes', () => {
    const newDay = '1992-06-30';
    const newTime = '08:00';

    findDatepicker().vm.$emit('input', toDate(newDay, newTime));
    expect(wrapper.emitted().input).toEqual([[toDate(newDay, testTime)]]);
  });

  it('emits Date with the old day/new time when the time picker changes', () => {
    const newTime = '08:00';

    findTimepicker().vm.$emit('input', newTime);
    expect(wrapper.emitted().input).toEqual([[toDate(testDay, newTime)]]);
  });
});
