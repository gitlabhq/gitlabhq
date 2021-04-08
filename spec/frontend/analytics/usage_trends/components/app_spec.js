import { shallowMount } from '@vue/test-utils';
import UsageTrendsApp from '~/analytics/usage_trends/components/app.vue';
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

  ['Total projects & groups', 'Pipelines', 'Issues & merge requests'].forEach((usage) => {
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
});
