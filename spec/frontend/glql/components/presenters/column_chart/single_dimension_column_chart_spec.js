import { GlColumnChart, GlStackedColumnChart } from '@gitlab/ui/src/charts';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SingleDimensionColumnChart from '~/glql/components/presenters/column_chart/single_dimension_column_chart.vue';

const DIMENSION = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
const TOTAL_COUNT = {
  key: 'totalCount',
  label: 'Total count',
  name: 'totalCount',
  type: 'metric',
};
const ACCEPTANCE_RATE = {
  key: 'acceptanceRate',
  label: 'Acceptance rate',
  name: 'acceptanceRate',
  type: 'metric',
};
const SHOWN = { key: 'shownCount', label: 'Shown', name: 'shownCount', type: 'metric' };
const ACCEPTED = { key: 'acceptedCount', label: 'Accepted', name: 'acceptedCount', type: 'metric' };
const REJECTED = { key: 'rejectedCount', label: 'Rejected', name: 'rejectedCount', type: 'metric' };
const DATA = {
  nodes: [
    {
      language: 'ruby',
      totalCount: 21,
      acceptanceRate: 0.625,
      shownCount: 8,
      acceptedCount: 5,
      rejectedCount: 8,
    },
    {
      language: 'python',
      totalCount: 14,
      acceptanceRate: 0.333,
      shownCount: 6,
      acceptedCount: 2,
      rejectedCount: 6,
    },
  ],
};

describe('SingleDimensionColumnChart', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(SingleDimensionColumnChart, {
      propsData: {
        data: DATA,
        dimension: DIMENSION,
        metrics: [TOTAL_COUNT],
        ...props,
      },
    });
  };

  const findColumnChart = () => wrapper.findComponent(GlColumnChart);
  const findStackedChart = () => wrapper.findComponent(GlStackedColumnChart);

  describe('with 1 metric', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GlColumnChart', () => {
      expect(findColumnChart().exists()).toBe(true);
      expect(findStackedChart().exists()).toBe(false);
    });

    it('labels the y-axis with the metric name', () => {
      expect(findColumnChart().props('yAxisTitle')).toBe('Total count');
    });

    it('passes the primary bar series', () => {
      expect(findColumnChart().props('bars')).toEqual([
        {
          name: 'Total count',
          data: [
            ['ruby', 21],
            ['python', 14],
          ],
        },
      ]);
    });

    it('passes empty secondary data', () => {
      expect(findColumnChart().props('secondaryData')).toEqual([]);
    });
  });

  describe('with 2 metrics (default — dual-axis)', () => {
    beforeEach(() => {
      createComponent({ metrics: [TOTAL_COUNT, ACCEPTANCE_RATE] });
    });

    it('renders GlColumnChart with dual-axis data', () => {
      expect(findColumnChart().exists()).toBe(true);
      expect(findStackedChart().exists()).toBe(false);
    });

    it('labels the left axis with metric[0] and right axis with metric[1]', () => {
      expect(findColumnChart().props('yAxisTitle')).toBe('Total count');
      expect(findColumnChart().props('secondaryDataTitle')).toBe('Acceptance rate');
    });

    it('passes metric[1] as secondary data', () => {
      expect(findColumnChart().props('secondaryData')).toEqual([
        {
          name: 'Acceptance rate',
          data: [
            ['ruby', 0.625],
            ['python', 0.333],
          ],
        },
      ]);
    });
  });

  describe('with 3+ metrics (grouped)', () => {
    beforeEach(() => {
      createComponent({ metrics: [SHOWN, ACCEPTED, REJECTED] });
    });

    it('renders GlStackedColumnChart in tiled presentation', () => {
      expect(findStackedChart().exists()).toBe(true);
      expect(findColumnChart().exists()).toBe(false);
      expect(findStackedChart().props('presentation')).toBe('tiled');
    });

    it('leaves the y-axis title empty (axis represents multiple metrics)', () => {
      expect(findStackedChart().props('yAxisTitle')).toBe('');
    });

    it('maps each metric to its own bar series', () => {
      expect(findStackedChart().props('bars')).toEqual([
        { name: 'Shown', data: [8, 6] },
        { name: 'Accepted', data: [5, 2] },
        { name: 'Rejected', data: [8, 6] },
      ]);
    });
  });

  describe('with 2 metrics and stacked=true', () => {
    beforeEach(() => {
      createComponent({ metrics: [TOTAL_COUNT, ACCEPTANCE_RATE], stacked: true });
    });

    it('renders GlStackedColumnChart in stacked presentation', () => {
      expect(findStackedChart().exists()).toBe(true);
      expect(findStackedChart().props('presentation')).toBe('stacked');
    });

    it('leaves the y-axis title empty', () => {
      expect(findStackedChart().props('yAxisTitle')).toBe('');
    });
  });

  describe('with 3+ metrics and stacked=true', () => {
    beforeEach(() => {
      createComponent({ metrics: [SHOWN, ACCEPTED, REJECTED], stacked: true });
    });

    it('renders GlStackedColumnChart in stacked presentation', () => {
      expect(findStackedChart().props('presentation')).toBe('stacked');
    });
  });
});
