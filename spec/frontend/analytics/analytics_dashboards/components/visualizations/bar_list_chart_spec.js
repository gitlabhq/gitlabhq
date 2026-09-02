import { GlChart } from '@gitlab/ui/src/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BarListChart from '~/analytics/analytics_dashboards/components/visualizations/bar_list_chart.vue';

describe('BarListChart', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const rows = [
    { name: 'Chat', value: 2570000, share: 90 },
    { name: 'Software Dev', value: 138300, share: 5 },
    { name: 'Other (6)', value: 23600, share: 0.8 },
  ];

  const findChart = () => wrapper.findComponent(GlChart);
  const chartOptions = () => findChart().props('options');
  const firstSeries = () => chartOptions().series[0];
  const labelAt = (dataIndex) => firstSeries().label.formatter({ dataIndex });
  const labelFor = (name) => labelAt(chartOptions().yAxis.data.indexOf(name));

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(BarListChart, { propsData: { data: rows, ...props } });
  };

  describe('rows', () => {
    beforeEach(() => createWrapper());

    // ECharts draws a category axis bottom-up, so the component reverses to
    // keep the caller's order reading top-down.
    it('reverses the categories so the given order reads top-down', () => {
      expect(chartOptions().yAxis.data).toEqual(['Other (6)', 'Software Dev', 'Chat']);
    });

    // The bar length is the share of the whole, not the value scaled against
    // the largest row, so the track reads as 100%.
    it('plots the shares rather than the values', () => {
      expect(firstSeries().data).toEqual([0.8, 5, 90]);
    });

    it('fixes the value axis to a full 100%', () => {
      expect(chartOptions().xAxis).toMatchObject({ min: 0, max: 100 });
    });
  });

  describe('value labels', () => {
    beforeEach(() => createWrapper());

    it.each`
      name              | expected
      ${'Chat'}         | ${'90% · 2.6M'}
      ${'Software Dev'} | ${'5% · 138.3k'}
      ${'Other (6)'}    | ${'0.8% · 23.6k'}
    `('renders $expected for $name', ({ name, expected }) => {
      expect(labelFor(name)).toBe(expected);
    });

    it('positions the label past the end of the bar', () => {
      expect(firstSeries().label).toMatchObject({ show: true, position: 'right' });
    });

    it('reserves room to the right of the plot area for the label', () => {
      expect(chartOptions().grid.right).toBeGreaterThan(0);
    });

    it('rounds a long share rather than printing it raw', () => {
      createWrapper({ data: [{ name: 'Chat', value: 1000, share: 0.83333 }] });

      expect(labelFor('Chat')).toBe('0.8% · 1k');
    });

    it('renders an empty label for an unknown category', () => {
      expect(labelFor('Nope')).toBe('');
    });
  });

  describe('chrome', () => {
    beforeEach(() => createWrapper());

    it('hides the value axis', () => {
      expect(chartOptions().xAxis.show).toBe(false);
    });

    it('hides the category axis ticks', () => {
      expect(chartOptions().yAxis.axisTick).toEqual({ show: false });
    });

    it('right-aligns the category labels outside the plot area', () => {
      expect(chartOptions().yAxis.axisLabel.align).toBe('right');
    });

    it('draws each bar against a track', () => {
      expect(firstSeries().showBackground).toBe(true);
    });

    it('fills the bars with a solid colour', () => {
      expect(firstSeries().itemStyle.color).toBeDefined();
    });
  });

  describe('when two rows share a name', () => {
    beforeEach(() =>
      createWrapper({
        data: [
          { name: 'Chat', value: 1000, share: 10 },
          { name: 'Chat', value: 2000, share: 20 },
        ],
      }),
    );

    // Index 0 is the last row, since the axis is drawn bottom-up.
    it('labels each bar from its own row', () => {
      expect(labelAt(0)).toBe('20% · 2k');
      expect(labelAt(1)).toBe('10% · 1k');
    });
  });

  describe('without data', () => {
    it('renders an empty chart rather than erroring', () => {
      createWrapper({ data: undefined });

      expect(chartOptions().yAxis.data).toEqual([]);
      expect(firstSeries().data).toEqual([]);
    });
  });

  describe('options passthrough', () => {
    beforeEach(() => createWrapper({ options: { grid: { right: 200 } } }));

    it('merges caller options over the defaults', () => {
      expect(chartOptions().grid.right).toBe(200);
    });

    it('keeps the defaults it does not override', () => {
      expect(chartOptions().xAxis.show).toBe(false);
    });
  });
});
