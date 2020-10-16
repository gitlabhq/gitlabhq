import { shallowMount } from '@vue/test-utils';
import InstanceStatisticsApp from '~/analytics/instance_statistics/components/app.vue';
import InstanceCounts from '~/analytics/instance_statistics/components//instance_counts.vue';
import PipelinesChart from '~/analytics/instance_statistics/components/pipelines_chart.vue';

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

  it('displays the pipelines chart component', () => {
    expect(wrapper.find(PipelinesChart).exists()).toBe(true);
  });
});
