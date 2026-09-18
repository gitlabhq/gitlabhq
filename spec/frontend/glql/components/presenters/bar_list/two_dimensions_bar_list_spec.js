import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TwoDimensionsBarList from '~/glql/components/presenters/bar_list/two_dimensions_bar_list.vue';
import BarListChart from '~/analytics/analytics_dashboards/components/visualizations/bar_list_chart.vue';

const USER = { key: 'user', label: 'User', name: 'user', type: 'dimension' };
const LANGUAGE = { key: 'language', label: 'Language', name: 'language', type: 'dimension' };
const DAILY = {
  key: 'created',
  label: 'Created',
  name: 'created',
  type: 'dimension',
  parameters: { granularity: 'daily' },
};
const METRIC = { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' };

// user x language cells; values sum to 100 so shares read as whole numbers.
const TWO_DIM_DATA = {
  nodes: [
    { user: 'alice', language: 'ruby', totalCount: 40 },
    { user: 'alice', language: 'go', totalCount: 10 },
    { user: 'bob', language: 'ruby', totalCount: 30 },
    { user: 'bob', language: 'python', totalCount: 20 },
  ],
};

describe('TwoDimensionsBarList', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(TwoDimensionsBarList, {
      propsData: {
        data: TWO_DIM_DATA,
        primaryDimension: USER,
        secondaryDimension: LANGUAGE,
        metric: METRIC,
        maxRows: 6,
        maxSeries: 6,
        ...props,
      },
    });
  };

  const findChart = () => wrapper.findComponent(BarListChart);
  const rows = () => findChart().props('data');

  it('groups rows by the primary dimension with a segment per secondary value', () => {
    createComponent();

    // Segments are ordered by the secondary values' grand totals: ruby 70,
    // python 20, go 10. Shares are of the grand total.
    expect(rows()).toEqual([
      {
        name: 'alice',
        value: 50,
        share: 50,
        segments: [
          { name: 'ruby', value: 40, share: 40 },
          { name: 'python', value: 0, share: 0 },
          { name: 'go', value: 10, share: 10 },
        ],
      },
      {
        name: 'bob',
        value: 50,
        share: 50,
        segments: [
          { name: 'ruby', value: 30, share: 30 },
          { name: 'python', value: 20, share: 20 },
          { name: 'go', value: 0, share: 0 },
        ],
      },
    ]);
  });

  it('renders no rows for an empty node list', () => {
    createComponent({ data: { nodes: [] } });

    expect(rows()).toEqual([]);
  });

  it('rolls secondary values beyond maxSeries into an Other segment', () => {
    createComponent({ maxSeries: 1 });

    expect(rows()[0].segments).toEqual([
      { name: 'ruby', value: 40, share: 40 },
      { name: 'Other (2)', value: 10, share: 10 },
    ]);
    expect(rows()[1].segments).toEqual([
      { name: 'ruby', value: 30, share: 30 },
      { name: 'Other (2)', value: 20, share: 20 },
    ]);
  });

  it('keeps a lone secondary value past the limit rather than naming it Other (1)', () => {
    createComponent({ maxSeries: 2 });

    expect(rows()[0].segments.map(({ name }) => name)).toEqual(['ruby', 'python', 'go']);
  });

  // Two raw buckets with the same formatted label stay separate segments,
  // named by their raw values, rather than merging silently into one.
  it('disambiguates secondary values whose formatted labels collide', () => {
    createComponent({
      data: {
        nodes: [
          { user: 'alice', created: '2026-06-01', totalCount: 5 },
          { user: 'alice', created: '2026-06-01T00:00:00Z', totalCount: 7 },
        ],
      },
      secondaryDimension: DAILY,
    });

    expect(rows()[0].segments.map(({ name }) => name)).toEqual([
      '2026-06-01T00:00:00Z',
      '2026-06-01',
    ]);
  });

  describe('row folding', () => {
    const fourUsers = {
      nodes: [
        { user: 'alice', language: 'ruby', totalCount: 50 },
        { user: 'bob', language: 'ruby', totalCount: 30 },
        { user: 'carol', language: 'ruby', totalCount: 15 },
        { user: 'dana', language: 'go', totalCount: 5 },
      ],
    };

    beforeEach(() => createComponent({ data: fourUsers, maxRows: 2 }));

    it('folds the rows past maxRows into an Other row with summed segments', () => {
      expect(rows().map(({ name }) => name)).toEqual(['alice', 'bob', 'Other (2)']);
      expect(rows()[2]).toEqual({
        name: 'Other (2)',
        value: 20,
        share: 20,
        segments: [
          { name: 'ruby', value: 15, share: 15 },
          { name: 'go', value: 5, share: 5 },
        ],
      });
    });

    it('keeps a lone row past the limit rather than folding it', async () => {
      await wrapper.setProps({ maxRows: 3 });

      expect(rows().map(({ name }) => name)).toEqual(['alice', 'bob', 'carol', 'dana']);
    });

    it('keeps bars summing to the grand total with the fold in place', () => {
      const total = rows().reduce((acc, { share }) => acc + share, 0);

      expect(total).toBe(100);
      expect(rows()[0].share).toBe(50);
    });
  });
});
