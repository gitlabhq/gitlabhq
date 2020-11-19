import { shallowMount } from '@vue/test-utils';
import InstanceStatisticsApp from '~/analytics/instance_statistics/components/app.vue';
import InstanceCounts from '~/analytics/instance_statistics/components//instance_counts.vue';
import InstanceStatisticsCountChart from '~/analytics/instance_statistics/components/instance_statistics_count_chart.vue';
import UsersChart from '~/analytics/instance_statistics/components/users_chart.vue';
import ProjectsAndGroupsChart from '~/analytics/instance_statistics/components/projects_and_groups_chart.vue';

describe('InstanceStatisticsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(InstanceStatisticsApp);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays the instance counts component', () => {
    expect(wrapper.find(InstanceCounts).exists()).toBe(true);
  });

  ['Pipelines', 'Issues & Merge Requests'].forEach(instance => {
    it(`displays the ${instance} chart`, () => {
      const chartTitles = wrapper
        .findAll(InstanceStatisticsCountChart)
        .wrappers.map(chartComponent => chartComponent.props('chartTitle'));

      expect(chartTitles).toContain(instance);
    });
  });

  it('displays the users chart component', () => {
    expect(wrapper.find(UsersChart).exists()).toBe(true);
  });

  it('displays the projects and groups chart component', () => {
    expect(wrapper.find(ProjectsAndGroupsChart).exists()).toBe(true);
  });
});
