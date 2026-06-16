import { shallowMount } from '@vue/test-utils';
import FormatTime from '~/analytics/analytics_dashboards/components/visualizations/data_table/format_time.vue';

describe('FormatTime', () => {
  it.each([
    ['2020-05-04', 'May 4, 2020'],
    ['', ''],
    [null, ''],
    [undefined, ''],
  ])('when time is `%s`, render `%s`', (timestamp, output) => {
    const wrapper = shallowMount(FormatTime, {
      propsData: {
        timestamp,
      },
    });

    expect(wrapper.text()).toBe(output);
  });
});
