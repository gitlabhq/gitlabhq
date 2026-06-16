import { mount } from '@vue/test-utils';
import MilestoneLink from '~/analytics/analytics_dashboards/components/visualizations/data_table/milestone_link.vue';

describe('MilestoneLink', () => {
  it('renders a link to the milestone', () => {
    const title = 'gon';
    const webPath = 'killua.com';
    const wrapper = mount(MilestoneLink, {
      propsData: { title, webPath },
    });

    expect(wrapper.text()).toBe(title);
    expect(wrapper.attributes('href')).toBe(webPath);
  });
});
