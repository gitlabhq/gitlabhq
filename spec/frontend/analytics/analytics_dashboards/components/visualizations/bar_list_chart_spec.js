import { GlChart } from '@gitlab/ui/src/charts';
import { GL_COLOR_DATA_BLUE_500, GL_COLOR_ORANGE_400 } from '@gitlab/ui/src/tokens/build/js/tokens';
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

  describe('height', () => {
    // The chart has to size itself: the wrappers between it and a dashboard
    // panel body are all auto-height, so a percentage height collapses.
    it('sizes itself from the row count rather than filling its container', () => {
      createWrapper();

      expect(wrapper.element.style.height).toBe('100px');

      createWrapper({ data: [...rows, ...rows] });

      expect(wrapper.element.style.height).toBe('184px');
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

  describe('scaled to the largest row', () => {
    beforeEach(() =>
      createWrapper({
        scale: 'max',
        data: [
          { name: 'Chat', value: 200, share: 50 },
          { name: 'Software Dev', value: 100, share: 25 },
          { name: 'Other (6)', value: 100, share: 25 },
        ],
      }),
    );

    it('fills the track with the largest row and sizes the rest against it', () => {
      expect(firstSeries().data).toEqual([50, 50, 100]);
    });

    it('keeps labelling each row with its share of the total', () => {
      expect(labelFor('Chat')).toBe('50% · 200');
    });

    it('draws every bar at zero length when all values are zero', () => {
      createWrapper({
        scale: 'max',
        data: [
          { name: 'Chat', value: 0, share: 0 },
          { name: 'Other (6)', value: 0, share: 0 },
        ],
      });

      expect(firstSeries().data).toEqual([0, 0]);
    });
  });

  describe('with blue bars', () => {
    beforeEach(() => createWrapper({ color: 'blue' }));

    // The palette's first colour, so the list matches the other charts' first series.
    it('fills the bars with the chart palette blue', () => {
      expect(firstSeries().itemStyle.color).toBe(GL_COLOR_DATA_BLUE_500);
    });
  });

  describe('with value-only labels', () => {
    beforeEach(() => createWrapper({ valueLabels: 'value' }));

    it.each`
      name              | expected
      ${'Chat'}         | ${'2,570,000'}
      ${'Software Dev'} | ${'138,300'}
      ${'Other (6)'}    | ${'23,600'}
    `('labels $name with its full value, $expected', ({ name, expected }) => {
      expect(labelFor(name)).toBe(expected);
    });

    // The value is the headline here rather than a footnote to the share.
    it('emphasises the value', () => {
      expect(firstSeries().label).toMatchObject({
        fontWeight: 'bold',
        color: 'var(--gl-text-color-default)',
      });
    });
  });

  describe('trends', () => {
    const rowsWithTrends = [
      { name: 'Chat', value: 1071, share: 60, trend: { text: '+7%', variant: 'success' } },
      { name: 'Duo Planner', value: 69, share: 30, trend: { text: '-4%', variant: 'danger' } },
      { name: 'Developer', value: 17, share: 10 },
    ];

    beforeEach(() => createWrapper({ data: rowsWithTrends, valueLabels: 'value' }));

    // ECharts rich text: a `{style|text}` segment takes its style from `label.rich`.
    it('appends each trend to its value label as a rich text pill, after a gap', () => {
      expect(labelFor('Chat')).toBe('1,071{trendGap|}{trendSuccess|+7%}');
      expect(labelFor('Duo Planner')).toBe('69{trendGap|}{trendDanger|-4%}');
    });

    it('sizes the gap with padding, since rich text has no margin', () => {
      expect(firstSeries().label.rich.trendGap).toEqual({ padding: [0, 4] });
    });

    it('leaves a row without a trend as its value alone', () => {
      expect(labelFor('Developer')).toBe('17');
    });

    it('colours each pill from the matching badge tokens', () => {
      expect(firstSeries().label.rich).toMatchObject({
        trendSuccess: {
          color: 'var(--gl-badge-success-text-color-default)',
          backgroundColor: 'var(--gl-badge-success-background-color-default)',
        },
        trendDanger: {
          color: 'var(--gl-badge-danger-text-color-default)',
          backgroundColor: 'var(--gl-badge-danger-background-color-default)',
        },
        trendNeutral: {
          color: 'var(--gl-badge-neutral-text-color-default)',
          backgroundColor: 'var(--gl-badge-neutral-background-color-default)',
        },
      });
    });

    it('widens the value column to make room for the pill', () => {
      const withTrends = chartOptions().grid.right;

      createWrapper({ data: rows });

      expect(withTrends).toBeGreaterThan(chartOptions().grid.right);
    });

    describe('with a variant the pill has no style for', () => {
      beforeEach(() =>
        createWrapper({
          data: [{ name: 'Chat', value: 10, share: 100, trend: { text: 'New', variant: 'info' } }],
        }),
      );

      it('falls back to the neutral pill', () => {
        expect(labelFor('Chat')).toBe('100% · 10{trendGap|}{trendNeutral|New}');
      });
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

    it('fills the bars orange by default', () => {
      expect(firstSeries().itemStyle.color).toBe(GL_COLOR_ORANGE_400);
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
