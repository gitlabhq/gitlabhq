import { GlSkeletonLoader } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BarListPresenter from '~/glql/components/presenters/bar_list.vue';
import DimensionRoutedChart from '~/glql/components/presenters/chart/dimension_routed_chart.vue';
import BarListChart from '~/analytics/analytics_dashboards/components/visualizations/bar_list_chart.vue';
import {
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_COMPARISON_DATA_ONE_DIM,
} from '../../mock_data';

// Deliberately not in value order, so the descending sort is observable.
const UNSORTED = {
  nodes: [
    { language: 'go', totalCount: 10 },
    { language: 'ruby', totalCount: 30 },
    { language: 'python', totalCount: 20 },
  ],
};

const eightRows = () => ({
  nodes: Array.from({ length: 8 }, (_, i) => ({
    language: `lang-${i}`,
    // Descending values, summing to 100 so shares read as whole numbers.
    totalCount: [30, 25, 15, 10, 8, 6, 4, 2][i],
  })),
});

const sevenRows = () => ({
  nodes: Array.from({ length: 7 }, (_, i) => ({
    language: `lang-${i}`,
    totalCount: [30, 25, 15, 10, 8, 6, 6][i],
  })),
});

describe('BarListPresenter', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(BarListPresenter, {
      propsData: {
        data: MOCK_AGGREGATED_DATA_ONE_DIM,
        fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
        ...props,
      },
      // Render the real routing shell so validation and loading behave as they
      // do in production; the chart itself stays stubbed.
      stubs: { DimensionRoutedChart },
    });
  };

  const findChart = () => wrapper.findComponent(BarListChart);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findEmittedErrorMessage = () => wrapper.emitted('error')?.[0]?.[0]?.message;
  const rows = () => findChart().props('data');

  describe('default', () => {
    beforeEach(() => createComponent());

    it('renders the chart', () => {
      expect(findChart().exists()).toBe(true);
    });

    it('gives each row a name, value and share of the total', () => {
      // 21 + 14 + 10 = 45
      expect(rows()).toEqual([
        { name: 'ruby', value: 21, share: (21 / 45) * 100 },
        { name: 'python', value: 14, share: (14 / 45) * 100 },
        { name: 'go', value: 10, share: (10 / 45) * 100 },
      ]);
    });

    it('makes the shares sum to 100', () => {
      const total = rows().reduce((sum, { share }) => sum + share, 0);

      expect(total).toBeCloseTo(100);
    });
  });

  describe('when the rows are not in value order', () => {
    beforeEach(() => createComponent({ data: UNSORTED }));

    it('sorts them descending by value', () => {
      expect(rows().map(({ name }) => name)).toEqual(['ruby', 'python', 'go']);
    });
  });

  describe('when there is no data', () => {
    it('renders no rows for an empty node list', () => {
      createComponent({ data: { nodes: [] } });

      expect(rows()).toEqual([]);
    });

    // Dividing by a zero total is the one arithmetic edge case here. The rows
    // still render, at zero length, rather than vanishing into a blank chart.
    it('gives every row a zero share when the total is zero', () => {
      createComponent({
        data: {
          nodes: [
            { language: 'ruby', totalCount: 0 },
            { language: 'go', totalCount: 0 },
          ],
        },
      });

      expect(rows()).toEqual([
        { name: 'ruby', value: 0, share: 0 },
        { name: 'go', value: 0, share: 0 },
      ]);
    });
  });

  describe('when the query returns more rows than the default maximum', () => {
    beforeEach(() => createComponent({ data: eightRows() }));

    it('keeps six rows and rolls the tail into one', () => {
      expect(rows()).toHaveLength(7);
      expect(
        rows()
          .slice(0, 6)
          .map(({ name }) => name),
      ).toEqual(['lang-0', 'lang-1', 'lang-2', 'lang-3', 'lang-4', 'lang-5']);
    });

    it('names the rolled-up row with the number of rows it covers', () => {
      expect(rows().at(-1)).toEqual({ name: 'Other (2)', value: 6, share: 6 });
    });

    it('still makes the shares sum to 100', () => {
      const total = rows().reduce((sum, { share }) => sum + share, 0);

      expect(total).toBeCloseTo(100);
    });
  });

  describe('when the query returns exactly one row more than the maximum', () => {
    beforeEach(() => createComponent({ data: sevenRows() }));

    it('keeps the row rather than naming it Other (1)', () => {
      expect(rows().map(({ name }) => name)).toEqual([
        'lang-0',
        'lang-1',
        'lang-2',
        'lang-3',
        'lang-4',
        'lang-5',
        'lang-6',
      ]);
    });
  });

  describe('with maxRows in the display config', () => {
    beforeEach(() => createComponent({ data: eightRows(), displayConfig: { maxRows: 4 } }));

    it('caps the rows at the configured number instead of the default', () => {
      expect(rows()).toHaveLength(5);
      expect(rows().at(-1)).toEqual({ name: 'Other (4)', value: 20, share: 20 });
    });
  });

  describe('when maxRows arrives as a YAML string', () => {
    beforeEach(() => createComponent({ data: eightRows(), displayConfig: { maxRows: '4' } }));

    it('caps the rows all the same', () => {
      expect(rows()).toHaveLength(5);
      expect(rows().at(-1).name).toBe('Other (4)');
    });
  });

  describe('when maxRows is not a positive whole number', () => {
    beforeEach(() => createComponent({ data: eightRows(), displayConfig: { maxRows: 0 } }));

    it('falls back to the default maximum', () => {
      expect(rows()).toHaveLength(7);
      expect(rows().at(-1).name).toBe('Other (2)');
    });
  });

  describe('when maxRows is larger than the default maximum', () => {
    beforeEach(() => createComponent({ data: eightRows(), displayConfig: { maxRows: 10 } }));

    it('widens the cap rather than clamping it back to the default', () => {
      expect(rows()).toHaveLength(8);
      expect(rows().at(-1).name).toBe('lang-7');
    });
  });

  describe('valueLabels', () => {
    it('defaults the chart to share and value labels', () => {
      createComponent();

      expect(findChart().props('valueLabels')).toBe('shareAndValue');
    });

    it('forwards a value-only format from the display config', () => {
      createComponent({ displayConfig: { valueLabels: 'value' } });

      expect(findChart().props('valueLabels')).toBe('value');
    });
  });

  describe('color', () => {
    it('defaults the chart to orange bars', () => {
      createComponent();

      expect(findChart().props('color')).toBe('orange');
    });

    it('forwards blue from the display config', () => {
      createComponent({ displayConfig: { color: 'blue' } });

      expect(findChart().props('color')).toBe('blue');
    });
  });

  describe('scale', () => {
    it('defaults the chart to bars sized by share of the total', () => {
      createComponent();

      expect(findChart().props('scale')).toBe('total');
    });

    it('forwards max from the display config', () => {
      createComponent({ displayConfig: { scale: 'max' } });

      expect(findChart().props('scale')).toBe('max');
    });

    it('forwards log from the display config', () => {
      createComponent({ displayConfig: { scale: 'log' } });

      expect(findChart().props('scale')).toBe('log');
    });
  });

  describe('when a display option has a value it does not know', () => {
    it.each`
      key              | value        | supportedValues
      ${'valueLabels'} | ${'percent'} | ${'`shareAndValue`, `value`'}
      ${'color'}       | ${'green'}   | ${'`orange`, `blue`'}
      ${'scale'}       | ${'largest'} | ${'`total`, `max`, `log`'}
    `('emits an error naming $key and renders no chart', ({ key, value, supportedValues }) => {
      createComponent({ displayConfig: { [key]: value } });

      expect(findEmittedErrorMessage()).toBe(
        `Unknown \`${key}\`: \`${value}\`. Supported values are: ${supportedValues}.`,
      );
      expect(findChart().exists()).toBe(false);
    });

    it('emits the error before the fields are populated', () => {
      createComponent({ fields: [], displayConfig: { color: 'green' } });

      expect(findEmittedErrorMessage()).toBe(
        'Unknown `color`: `green`. Supported values are: `orange`, `blue`.',
      );
    });
  });

  describe('with comparison data', () => {
    const trendProps = {
      comparisonData: MOCK_AGGREGATED_COMPARISON_DATA_ONE_DIM,
      source: 'CodeSuggestions',
    };
    const trendOf = (name) => rows().find((row) => row.name === name).trend;

    beforeEach(() => createComponent(trendProps));

    // ruby: 21 against 20. python: 14 against 14. go has no previous row.
    it('gives each paired row a signed change, coloured by its direction', () => {
      expect(rows()).toEqual([
        {
          name: 'ruby',
          value: 21,
          share: (21 / 45) * 100,
          trend: { text: '+5%', variant: 'success' },
        },
        {
          name: 'python',
          value: 14,
          share: (14 / 45) * 100,
          trend: { text: '0%', variant: 'neutral' },
        },
        { name: 'go', value: 10, share: (10 / 45) * 100 },
      ]);
    });

    describe('when a value falls', () => {
      beforeEach(() =>
        createComponent({
          ...trendProps,
          data: { nodes: [{ language: 'ruby', totalCount: 15 }] },
        }),
      );

      it('marks the fall as a bad move for a count', () => {
        expect(trendOf('ruby')).toEqual({ text: '-25%', variant: 'danger' });
      });
    });

    describe('when the metric is better going down', () => {
      beforeEach(() =>
        createComponent({
          ...trendProps,
          fields: [
            MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC[0],
            { key: 'rejectedCount', label: 'Rejected count', type: 'metric' },
          ],
          data: { nodes: [{ language: 'ruby', rejectedCount: 30 }] },
          comparisonData: { nodes: [{ language: 'ruby', rejectedCount: 20 }] },
        }),
      );

      it('marks a rise as a bad move', () => {
        expect(trendOf('ruby')).toEqual({ text: '+50%', variant: 'danger' });
      });
    });

    describe('when the previous value was 0', () => {
      beforeEach(() =>
        createComponent({
          ...trendProps,
          comparisonData: { nodes: [{ language: 'ruby', totalCount: 0 }] },
        }),
      );

      // A move from 0 has no percentage to show.
      it('says the row is new', () => {
        expect(trendOf('ruby')).toEqual({ text: 'New', variant: 'neutral' });
      });
    });

    describe('when the rows roll up into Other', () => {
      // The two folded rows moved from 2 + 1 to 4 + 2.
      const previous = (values) => ({
        nodes: values.map((totalCount, i) => ({ language: `lang-${i}`, totalCount })),
      });

      beforeEach(() =>
        createComponent({
          ...trendProps,
          data: eightRows(),
          comparisonData: previous([30, 25, 15, 10, 8, 6, 2, 1]),
        }),
      );

      it('compares the roll-up against the sum of its rows in the previous period', () => {
        expect(rows().at(-1)).toEqual({
          name: 'Other (2)',
          value: 6,
          share: 6,
          trend: { text: '+100%', variant: 'success' },
        });
      });

      describe('and one folded row has no previous value', () => {
        beforeEach(() =>
          createComponent({
            ...trendProps,
            data: eightRows(),
            comparisonData: previous([30, 25, 15, 10, 8, 6, 2]),
          }),
        );

        it('leaves the roll-up without a trend, since its previous total is unknown', () => {
          expect(rows().at(-1)).toEqual({ name: 'Other (2)', value: 6, share: 6 });
          expect(trendOf('lang-0')).toEqual({ text: '0%', variant: 'neutral' });
        });
      });
    });

    describe('when the previous period returned no rows', () => {
      beforeEach(() => createComponent({ ...trendProps, comparisonData: { nodes: [] } }));

      it('gives no row a trend', () => {
        expect(rows().every((row) => !('trend' in row))).toBe(true);
      });
    });

    describe('when the dimension buckets by date', () => {
      beforeEach(() =>
        createComponent({
          ...trendProps,
          fields: [
            {
              key: 'created',
              label: 'Created',
              type: 'dimension',
              parameters: { granularity: 'weekly' },
            },
            MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC[1],
          ],
          data: { nodes: [{ created: '2026-01-05', totalCount: 10 }] },
          comparisonData: { nodes: [{ created: '2025-12-29', totalCount: 5 }] },
        }),
      );

      // The buckets are different dates in the shifted window, so nothing pairs.
      it('gives no row a trend', () => {
        expect(rows()).toHaveLength(1);
        expect(rows()[0]).not.toHaveProperty('trend');
      });
    });

    describe('when a row is duplicated in the previous period', () => {
      beforeEach(() =>
        createComponent({
          ...trendProps,
          comparisonData: {
            nodes: [
              { language: 'ruby', totalCount: 5 },
              { language: 'ruby', totalCount: 15 },
            ],
          },
        }),
      );

      it('gives no row a trend, since either pairing would be a guess', () => {
        expect(rows().every((row) => !('trend' in row))).toBe(true);
      });
    });
  });

  describe('loading', () => {
    beforeEach(() => createComponent({ loading: true }));

    it('renders the skeleton loader and no chart', () => {
      expect(findSkeletonLoader().exists()).toBe(true);
      expect(findChart().exists()).toBe(false);
    });
  });

  describe('validation', () => {
    it('rejects a second dimension', () => {
      createComponent({ fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC });

      expect(findChart().exists()).toBe(false);
      expect(findEmittedErrorMessage()).toBe('barList supports exactly one dimension');
    });
  });
});
