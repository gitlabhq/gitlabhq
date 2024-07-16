import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DateRangesDropdown from '~/analytics/shared/components/date_ranges_dropdown.vue';
import DateRangeFilter from '~/observability/components/date_range_filter.vue';
import DatetimeRangePicker from '~/observability/components/datetime_range_picker.vue';
import { useFakeDate } from 'helpers/fake_date';

describe('DateRangeFilter', () => {
  // Apr 23th, 2024 4:00 (3 = April)
  useFakeDate(2024, 3, 23, 4);

  let wrapper;

  const defaultProps = {
    selected: {
      value: '1h',
      startDate: new Date(),
      endDate: new Date(),
    },
  };

  const mount = (props = defaultProps) => {
    wrapper = shallowMountExtended(DateRangeFilter, {
      propsData: props,
    });
  };

  beforeEach(() => {
    mount();
  });

  const findDateRangesDropdown = () => wrapper.findComponent(DateRangesDropdown);
  const findDatetimeRangesPicker = () => wrapper.findComponent(DatetimeRangePicker);

  it('renders the date ranges dropdown with the default selected value and options', () => {
    const dateRangesDropdown = findDateRangesDropdown();
    expect(dateRangesDropdown.exists()).toBe(true);
    expect(dateRangesDropdown.props('selected')).toBe(defaultProps.selected.value);
    expect(dateRangesDropdown.props('dateRangeOptions')).toMatchInlineSnapshot(`
[
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-23T03:55:00.000Z,
    "text": "Last 5 minutes",
    "value": "5m",
  },
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-23T03:45:00.000Z,
    "text": "Last 15 minutes",
    "value": "15m",
  },
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-23T03:30:00.000Z,
    "text": "Last 30 minutes",
    "value": "30m",
  },
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-23T03:00:00.000Z,
    "text": "Last 1 hour",
    "value": "1h",
  },
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-23T00:00:00.000Z,
    "text": "Last 4 hours",
    "value": "4h",
  },
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-22T16:00:00.000Z,
    "text": "Last 12 hours",
    "value": "12h",
  },
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-22T04:00:00.000Z,
    "text": "Last 24 hours",
    "value": "24h",
  },
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-16T04:00:00.000Z,
    "text": "Last 7 days",
    "value": "7d",
  },
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-09T04:00:00.000Z,
    "text": "Last 14 days",
    "value": "14d",
  },
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-03-24T04:00:00.000Z,
    "text": "Last 30 days",
    "value": "30d",
  },
]
`);
  });

  it('renders dateRangeOptions based on dateOptions if specified', () => {
    mount({ ...defaultProps, dateOptions: [{ value: '7m', title: 'Last 7 minutes' }] });

    expect(findDateRangesDropdown().props('dateRangeOptions')).toMatchInlineSnapshot(`
[
  {
    "endDate": 2024-04-23T04:00:00.000Z,
    "startDate": 2024-04-23T03:53:00.000Z,
    "text": "Last 7 minutes",
    "value": "7m",
  },
]
`);
  });

  it('does not set the selected value if not specified', () => {
    mount({ selected: undefined });

    expect(findDateRangesDropdown().props('selected')).toBe('');
  });

  it('renders the daterange-picker if custom option is selected', () => {
    const timeRange = {
      startDate: new Date('2022-01-01'),
      endDate: new Date('2022-01-02'),
    };
    mount({
      selected: { value: 'custom', startDate: timeRange.startDate, endDate: timeRange.endDate },
    });

    expect(findDatetimeRangesPicker().exists()).toBe(true);
    expect(findDatetimeRangesPicker().props('defaultStartDate')).toBe(timeRange.startDate);
    expect(findDatetimeRangesPicker().props('defaultEndDate')).toBe(timeRange.endDate);
  });

  it('emits the onDateRangeSelected event when the time range is selected', async () => {
    const timeRange = {
      value: '24h',
      startDate: new Date('2022-01-01'),
      endDate: new Date('2022-01-02'),
    };
    await findDateRangesDropdown().vm.$emit('selected', timeRange);

    expect(wrapper.emitted('onDateRangeSelected')).toEqual([[{ ...timeRange }]]);
  });

  it('emits the onDateRangeSelected event when a custom time range is selected', async () => {
    const timeRange = {
      startDate: new Date('2021-01-01'),
      endDate: new Date('2021-01-02'),
    };
    await findDateRangesDropdown().vm.$emit('customDateRangeSelected');

    expect(findDatetimeRangesPicker().props('startOpened')).toBe(true);
    expect(wrapper.emitted('onDateRangeSelected')).toBeUndefined();

    await findDatetimeRangesPicker().vm.$emit('input', timeRange);

    expect(wrapper.emitted('onDateRangeSelected')).toEqual([
      [
        {
          ...timeRange,
          value: 'custom',
        },
      ],
    ]);
  });

  describe('start opened', () => {
    it('sets startOpened to true if custom date is selected without start and end date', () => {
      mount({ selected: { value: 'custom' } });

      expect(findDatetimeRangesPicker().props('startOpened')).toBe(true);
    });

    it('sets startOpened to false if custom date is selected with start and end date', () => {
      mount({
        selected: {
          value: 'custom',
          startDate: new Date('2022-01-01'),
          endDate: new Date('2022-01-02'),
        },
      });

      expect(findDatetimeRangesPicker().props('startOpened')).toBe(false);
    });

    it('sets startOpend to true if customDateRangeSelected is emitted', async () => {
      await findDateRangesDropdown().vm.$emit('customDateRangeSelected');

      expect(findDatetimeRangesPicker().props('startOpened')).toBe(true);
    });
  });

  it('sets the max-date to tomorrow', async () => {
    await findDateRangesDropdown().vm.$emit('customDateRangeSelected');

    expect(findDatetimeRangesPicker().props('defaultMaxDate').toISOString()).toBe(
      '2024-04-24T00:00:00.000Z',
    );
  });

  it('pass through the min-date prop', async () => {
    const minDate = new Date('2024-04-24T00:00:00.000Z');
    mount({ ...defaultProps, defaultMinDate: minDate });

    await findDateRangesDropdown().vm.$emit('customDateRangeSelected');

    expect(findDatetimeRangesPicker().props('defaultMinDate').toISOString()).toBe(
      '2024-04-24T00:00:00.000Z',
    );
  });

  it('sets max-date-range to maxDateRange', () => {
    mount({
      selected: {
        value: 'custom',
        startDate: new Date('2022-01-01'),
        endDate: new Date('2022-01-02'),
      },
      maxDateRange: 7,
    });

    expect(findDatetimeRangesPicker().props('maxDateRange')).toBe(7);
  });

  it('sets dateTimeRangePickerState to state', () => {
    mount({
      selected: {
        value: 'custom',
        startDate: new Date('2022-01-01'),
        endDate: new Date('2022-01-02'),
      },
      dateTimeRangePickerState: false,
    });

    expect(findDatetimeRangesPicker().props('state')).toBe(false);
  });
});
