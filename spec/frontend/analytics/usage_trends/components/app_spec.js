import { shallowMount } from '@vue/test-utils';
import UsageTrendsApp from '~/analytics/usage_trends/components/app.vue';
import ProjectsAndGroupsChart from '~/analytics/usage_trends/components/projects_and_groups_chart.vue';
import UsageCounts from '~/analytics/usage_trends/components/usage_counts.vue';
import UsageTrendsCountChart from '~/analytics/usage_trends/components/usage_trends_count_chart.vue';
import UsersChart from '~/analytics/usage_trends/components/users_chart.vue';

describe('UsageTrendsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(UsageTrendsApp);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays the usage counts component', () => {
    expect(wrapper.find(UsageCounts).exists()).toBe(true);
  });

  ['Pipelines', 'Issues & Merge Requests'].forEach((usage) => {
    it(`displays the ${usage} chart`, () => {
      const chartTitles = wrapper
        .findAll(UsageTrendsCountChart)
        .wrappers.map((chartComponent) => chartComponent.props('chartTitle'));

      expect(chartTitles).toContain(usage);
    });
  });

  it('displays the users chart component', () => {
    expect(wrapper.find(UsersChart).exists()).toBe(true);
  });

  it('displays the projects and groups chart component', () => {
    expect(wrapper.find(ProjectsAndGroupsChart).exists()).toBe(true);
  });
});
