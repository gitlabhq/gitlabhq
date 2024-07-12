import { GlDaterangePicker, GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DatetimeRangePicker from '~/observability/components/datetime_range_picker.vue';

describe('DatetimeRangePicker', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(DatetimeRangePicker, {
      propsData: props,
    });
  };

  const findGlDaterangePicker = () => wrapper.findComponent(GlDaterangePicker);
  const findGlFormInputs = () => wrapper.findAllComponents(GlFormInput);
  const findStartTimeInput = () => findGlFormInputs().at(0);
  const findEndTimeInput = () => findGlFormInputs().at(1);

  const defaultProps = {
    startOpened: true,
    defaultMaxDate: new Date('2024-01-02T04:05:06Z'),
    defaultMinDate: new Date('2024-01-01T04:05:06Z'),
    maxDateRange: 7,
  };

  const defaultStartDate = new Date('2023-01-01T01:02:03Z');
  const defaultEndDate = new Date('2023-01-02T04:05:06Z');

  it('renders GlDaterangePicker and GlFormInput components', () => {
    createComponent();

    expect(findGlDaterangePicker().exists()).toBe(true);
    expect(findStartTimeInput().exists()).toBe(true);
    expect(findEndTimeInput().exists()).toBe(true);
  });

  it('initializes data correctly', () => {
    createComponent(defaultProps);

    expect(findGlDaterangePicker().props('startOpened')).toBe(defaultProps.startOpened);
    expect(findGlDaterangePicker().props('defaultMaxDate')).toEqual(defaultProps.defaultMaxDate);
    expect(findGlDaterangePicker().props('defaultMinDate')).toBe(defaultProps.defaultMinDate);
    expect(findGlDaterangePicker().props('maxDateRange')).toBe(defaultProps.maxDateRange);
  });

  it('initialises dates/times when no default dates are provided', () => {
    createComponent();

    expect(findGlDaterangePicker().props('defaultStartDate')).toBeNull();
    expect(findGlDaterangePicker().props('defaultEndDate')).toBeNull();
    expect(findStartTimeInput().attributes('value')).toEqual('00:00:00');
    expect(findEndTimeInput().attributes('value')).toEqual('00:00:00');
  });

  it('initialises dates/times based on default start/end date', () => {
    createComponent({ defaultStartDate, defaultEndDate });

    expect(findGlDaterangePicker().props('defaultStartDate')).toEqual(defaultStartDate);
    expect(findGlDaterangePicker().props('defaultEndDate')).toEqual(defaultEndDate);
    expect(findStartTimeInput().attributes('value')).toEqual('01:02:03');
    expect(findEndTimeInput().attributes('value')).toEqual('04:05:06');
  });

  it('emits correct values on date range change', async () => {
    createComponent({ defaultStartDate, defaultEndDate });

    const newStartDate = new Date('2023-01-03T00:00:00Z');
    const newEndDate = new Date('2023-01-04T00:00:00Z');

    await findGlDaterangePicker().vm.$emit('input', {
      startDate: newStartDate,
      endDate: newEndDate,
    });

    expect(wrapper.emitted().input[0]).toEqual([
      {
        startDate: new Date('2023-01-03T01:02:03Z'),
        endDate: new Date('2023-01-04T04:05:06Z'),
      },
    ]);
  });

  it('emits correct values on start time input blur', async () => {
    createComponent({ defaultStartDate, defaultEndDate });

    await findStartTimeInput().vm.$emit('input', '13:14:15');
    await findStartTimeInput().vm.$emit('blur');

    expect(wrapper.emitted().input[0]).toEqual([
      {
        startDate: new Date('2023-01-01T13:14:15Z'),
        endDate: new Date('2023-01-02T04:05:06Z'),
      },
    ]);
  });

  it('emits correct values on end time input blur', async () => {
    createComponent({ defaultStartDate, defaultEndDate });

    await findEndTimeInput().vm.$emit('input', '13:14:15');
    await findEndTimeInput().vm.$emit('blur');

    expect(wrapper.emitted().input[0]).toEqual([
      {
        endDate: new Date('2023-01-02T13:14:15Z'),
        startDate: new Date('2023-01-01T01:02:03Z'),
      },
    ]);
  });

  it('does not emit values on time input blur if time does not change', async () => {
    createComponent({ defaultStartDate, defaultEndDate });

    findStartTimeInput().vm.$emit('input', '01:02:03');
    findEndTimeInput().vm.$emit('input', '04:05:06');

    await findEndTimeInput().vm.$emit('blur');

    expect(wrapper.emitted().input).toBeUndefined();
  });

  it('does not emit values on time input blur if dates are not set', async () => {
    createComponent();

    findStartTimeInput().vm.$emit('input', '01:02:03');
    findEndTimeInput().vm.$emit('input', '04:05:06');

    await findEndTimeInput().vm.$emit('blur');

    expect(wrapper.emitted().input).toBeUndefined();
  });

  it('sets the state props of the underlying components', () => {
    createComponent({ ...defaultProps, state: false });

    expect(findGlDaterangePicker().props('startPickerState')).toEqual(false);
    expect(findGlDaterangePicker().props('endPickerState')).toEqual(false);
  });
});
