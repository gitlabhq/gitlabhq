import { mount } from '@vue/test-utils';
import DiffLineChanges from '~/analytics/analytics_dashboards/components/visualizations/data_table/diff_line_changes.vue';

describe('DiffLineChanges', () => {
  it('renders the lines added/deleted', () => {
    const wrapper = mount(DiffLineChanges, {
      propsData: {
        additions: 100,
        deletions: 50,
      },
    });

    expect(wrapper.text()).toBe('+100 -50');
  });
});
