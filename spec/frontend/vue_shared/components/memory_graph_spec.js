import Vue from 'vue';
import { shallowMount } from '@vue/test-utils';
import MemoryGraph from '~/vue_shared/components/memory_graph.vue';
import { GlSparklineChart } from '@gitlab/ui/dist/charts';

describe('MemoryGraph', () => {
  const Component = Vue.extend(MemoryGraph);
  let wrapper;
  const metrics = [
    [1573586253.853, '2.87'],
    [1573586313.853, '2.77734375'],
    [1573586373.853, '2.77734375'],
    [1573586433.853, '3.0066964285714284'],
  ];

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    wrapper = shallowMount(Component, {
      propsData: {
        metrics,
        width: 100,
        height: 25,
      },
    });
  });

  describe('chartData', () => {
    it('should calculate chartData', () => {
      expect(wrapper.vm.chartData.length).toEqual(metrics.length);
    });

    it('should format date & MB values', () => {
      const formattedData = [
        ['Nov 12 2019 19:17:33', '2.87'],
        ['Nov 12 2019 19:18:33', '2.78'],
        ['Nov 12 2019 19:19:33', '2.78'],
        ['Nov 12 2019 19:20:33', '3.01'],
      ];
      expect(wrapper.vm.chartData).toEqual(formattedData);
    });
  });

  describe('Render chart', () => {
    it('should draw container with chart', () => {
      expect(wrapper.element).toMatchSnapshot();
      expect(wrapper.find('.memory-graph-container').exists()).toBe(true);
      expect(wrapper.find(GlSparklineChart).exists()).toBe(true);
    });
  });
});
