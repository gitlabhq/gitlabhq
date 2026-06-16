import { shallowMount } from '@vue/test-utils';
import FormatTimeRange from '~/analytics/analytics_dashboards/components/visualizations/data_table/format_time_range.vue';

describe('FormatTimeRange', () => {
  it.each([
    ['2020-05-04T00:00:00Z', '2020-05-04T12:00:00Z', 'about 12 hours'],
    ['2020-05-04', '2020-05-06', '2 days'],
    ['2020-05-04', '', ''],
    ['2020-05-04', null, ''],
    ['2020-05-04', undefined, ''],
    ['', '2020-05-06', ''],
    [null, '2020-05-06', ''],
    [undefined, '2020-05-06', ''],
  ])('when time range is (%s, %s), render `%s`', (startTimestamp, endTimestamp, output) => {
    const wrapper = shallowMount(FormatTimeRange, {
      propsData: {
        startTimestamp,
        endTimestamp,
      },
    });

    expect(wrapper.text()).toBe(output);
  });
});
