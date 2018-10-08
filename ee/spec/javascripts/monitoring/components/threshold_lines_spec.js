import Vue from 'vue';
import ThresholdLines from 'ee/monitoring/components/threshold_lines.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { generateGraphDrawData } from '~/monitoring/utils/multiple_time_series';
import { singleRowMetricsMultipleSeries, convertDatesMultipleSeries } from 'spec/monitoring/mock_data';

const width = 500;
const height = 200;
const heightOffset = 50;

describe('ThresholdLines', () => {
  let Component;
  let vm;
  const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);
  const { queries } = convertedMetrics[0];
  const graphDrawData = generateGraphDrawData(queries, width, height, heightOffset);

  beforeEach(() => {
    Component = Vue.extend(ThresholdLines);
    spyOn(graphDrawData, 'areaAboveLine').and.callThrough();
    spyOn(graphDrawData, 'areaBelowLine').and.callThrough();
    spyOn(graphDrawData, 'lineFunction').and.callThrough();
  });

  describe('< alerts', () => {
    beforeEach(() => {
      const props = {
        operator: '<',
        threshold: 0.6,
        graphDrawData,
      };
      vm = mountComponent(Component, props);
    });

    it('fills area', () => {
      expect(vm.$el.querySelectorAll('path').length).toEqual(2);
      expect(graphDrawData.areaBelowLine).toHaveBeenCalled();
      expect(graphDrawData.lineFunction).toHaveBeenCalled();
    });
  });

  describe('> alerts', () => {
    it('fills area', () => {
      const props = {
        operator: '>',
        threshold: 0.6,
        graphDrawData,
      };
      vm = mountComponent(Component, props);

      expect(vm.$el.querySelectorAll('path').length).toEqual(2);
      expect(graphDrawData.areaAboveLine).toHaveBeenCalled();
      expect(graphDrawData.lineFunction).toHaveBeenCalled();
    });

    it('hides area if threshold out of range', () => {
      const props = {
        operator: '>',
        threshold: 1000,
        graphDrawData,
      };

      vm = mountComponent(Component, props);

      expect(vm.$el.innerHTML).not.toBeDefined();
      expect(graphDrawData.areaAboveLine).not.toHaveBeenCalled();
      expect(graphDrawData.lineFunction).not.toHaveBeenCalled();
    });
  });

  describe('= alerts', () => {
    it('draws line only', () => {
      const props = {
        operator: '=',
        threshold: 0.6,
        graphDrawData,
      };
      vm = mountComponent(Component, props);

      expect(vm.$el.querySelectorAll('path').length).toEqual(1);
      expect(graphDrawData.lineFunction).toHaveBeenCalled();
    });
  });
});
