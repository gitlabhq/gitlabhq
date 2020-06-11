import { shallowMount } from '@vue/test-utils';
import timezoneMock from 'timezone-mock';
import { cloneDeep } from 'lodash';
import { GlStackedColumnChart } from '@gitlab/ui/dist/charts';
import StackedColumnChart from '~/monitoring/components/charts/stacked_column.vue';
import { stackedColumnMockedData } from '../../mock_data';

jest.mock('~/lib/utils/icon_utils', () => ({
  getSvgIconPathContent: jest.fn().mockImplementation(icon => Promise.resolve(`${icon}-content`)),
}));

describe('Stacked column chart component', () => {
  let wrapper;
  const findChart = () => wrapper.find(GlStackedColumnChart);

  const createWrapper = (props = {}) => {
    wrapper = shallowMount(StackedColumnChart, {
      propsData: {
        graphData: stackedColumnMockedData,
        ...props,
      },
    });
  };

  describe('when graphData is present', () => {
    beforeEach(() => {
      createWrapper();
      return wrapper.vm.$nextTick();
    });

    it('chart is rendered', () => {
      expect(findChart().exists()).toBe(true);
    });

    it('data should match the graphData y value for each series', () => {
      const data = findChart().props('data');

      data.forEach((series, index) => {
        const { values } = stackedColumnMockedData.metrics[index].result[0];
        expect(series).toEqual(values.map(value => value[1]));
      });
    });

    it('series names should be the same as the graphData metrics labels', () => {
      const seriesNames = findChart().props('seriesNames');

      expect(seriesNames).toHaveLength(stackedColumnMockedData.metrics.length);
      seriesNames.forEach((name, index) => {
        expect(stackedColumnMockedData.metrics[index].label).toBe(name);
      });
    });

    it('group by should be the same as the graphData first metric results', () => {
      const groupBy = findChart().props('groupBy');

      expect(groupBy).toEqual([
        '2020-01-30T12:00:00.000Z',
        '2020-01-30T12:01:00.000Z',
        '2020-01-30T12:02:00.000Z',
      ]);
    });

    it('chart options should configure data zoom and axis label ', () => {
      const chartOptions = findChart().props('option');
      const xAxisType = findChart().props('xAxisType');

      expect(chartOptions).toMatchObject({
        dataZoom: [{ handleIcon: 'path://scroll-handle-content' }],
        xAxis: {
          axisLabel: { formatter: expect.any(Function) },
        },
      });

      expect(xAxisType).toBe('category');
    });

    it('chart options should configure category as x axis type', () => {
      const chartOptions = findChart().props('option');
      const xAxisType = findChart().props('xAxisType');

      expect(chartOptions).toMatchObject({
        xAxis: {
          type: 'category',
        },
      });
      expect(xAxisType).toBe('category');
    });

    it('format date is correct', () => {
      const { xAxis } = findChart().props('option');
      expect(xAxis.axisLabel.formatter('2020-01-30T12:01:00.000Z')).toBe('12:01 PM');
    });

    describe('when in PT timezone', () => {
      beforeAll(() => {
        timezoneMock.register('US/Pacific');
      });

      afterAll(() => {
        timezoneMock.unregister();
      });

      it('date is shown in local time', () => {
        const { xAxis } = findChart().props('option');
        expect(xAxis.axisLabel.formatter('2020-01-30T12:01:00.000Z')).toBe('4:01 AM');
      });

      it('date is shown in UTC', () => {
        wrapper.setProps({ timezone: 'UTC' });

        return wrapper.vm.$nextTick().then(() => {
          const { xAxis } = findChart().props('option');
          expect(xAxis.axisLabel.formatter('2020-01-30T12:01:00.000Z')).toBe('12:01 PM');
        });
      });
    });
  });

  describe('when graphData has results missing', () => {
    beforeEach(() => {
      const graphData = cloneDeep(stackedColumnMockedData);

      graphData.metrics[0].result = null;

      createWrapper({ graphData });
      return wrapper.vm.$nextTick();
    });

    it('chart is rendered', () => {
      expect(findChart().exists()).toBe(true);
    });
  });
});
