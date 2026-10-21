import { nextTick } from 'vue';
import { GlBadge, GlIcon } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ThResizable from '~/glql/components/common/th_resizable.vue';
import AreaChartPresenter from '~/glql/components/presenters/area_chart.vue';
import BarChartPresenter from '~/glql/components/presenters/bar_chart.vue';
import BarListPresenter from '~/glql/components/presenters/bar_list.vue';
import ColumnChartPresenter from '~/glql/components/presenters/column_chart.vue';
import LineChartPresenter from '~/glql/components/presenters/line_chart.vue';
import ListPresenter from '~/glql/components/presenters/list.vue';
import StatPresenter from '~/glql/components/presenters/stat.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import HeatMapPresenter from '~/glql/components/presenters/heat_map.vue';
import DivergingBarChartPresenter from '~/glql/components/presenters/diverging_bar_chart.vue';
import DataPresenter from '~/glql/components/presenters/data.vue';
import {
  MOCK_FIELDS,
  MOCK_ISSUES,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
  MOCK_AGGREGATED_COMPARISON_DATA_ONE_DIM,
  MOCK_AGGREGATED_DATA_OBJECT_DIM,
  MOCK_AGGREGATED_FIELDS_OBJECT_DIM,
} from '../../mock_data';

const MOCK_STAT_FIELDS = [
  { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' },
];

describe('DataPresenter', () => {
  it.each`
    displayType            | fields                                        | presenterProps                                            | PresenterComponent
    ${'list'}              | ${MOCK_FIELDS}                                | ${{ fields: MOCK_FIELDS, listType: 'ul' }}                | ${ListPresenter}
    ${'orderedList'}       | ${MOCK_FIELDS}                                | ${{ fields: MOCK_FIELDS, listType: 'ol' }}                | ${ListPresenter}
    ${'table'}             | ${MOCK_FIELDS}                                | ${{ fields: MOCK_FIELDS }}                                | ${TablePresenter}
    ${'stat'}              | ${MOCK_STAT_FIELDS}                           | ${{ fields: MOCK_STAT_FIELDS }}                           | ${StatPresenter}
    ${'columnChart'}       | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC}  | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC }}  | ${ColumnChartPresenter}
    ${'lineChart'}         | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC}  | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC }}  | ${LineChartPresenter}
    ${'barChart'}          | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC}  | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC }}  | ${BarChartPresenter}
    ${'barList'}           | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC}  | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC }}  | ${BarListPresenter}
    ${'areaChart'}         | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC}  | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC }}  | ${AreaChartPresenter}
    ${'heatMap'}           | ${MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC} | ${{ fields: MOCK_AGGREGATED_FIELDS_TWO_DIMS_ONE_METRIC }} | ${HeatMapPresenter}
    ${'divergingBarChart'} | ${MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS} | ${{ fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS }} | ${DivergingBarChartPresenter}
  `(
    'inits appropriate presenter for displayType: $displayType',
    ({ displayType, fields, presenterProps, PresenterComponent }) => {
      const data = MOCK_ISSUES;

      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: { data, displayType, fields },
      });

      const presenter = wrapper.findComponent(PresenterComponent);

      expect(presenter.props('data')).toBe(data);
      expect(presenter.props('loading')).toBe(false);

      for (const [key, value] of Object.entries(presenterProps)) {
        expect(presenter.props(key)).toBe(value);
      }
    },
  );

  describe.each`
    displayType      | PresenterComponent
    ${'columnChart'} | ${ColumnChartPresenter}
    ${'barChart'}    | ${BarChartPresenter}
    ${'barList'}     | ${BarListPresenter}
    ${'areaChart'}   | ${AreaChartPresenter}
    ${'heatMap'}     | ${HeatMapPresenter}
  `('$displayType', ({ displayType, PresenterComponent }) => {
    it('forwards displayConfig to the presenter', () => {
      const displayConfig = { stacked: true };

      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType,
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
          displayConfig,
        },
      });

      expect(wrapper.findComponent(PresenterComponent).props('displayConfig')).toBe(displayConfig);
    });

    it('re-emits errors from the presenter', () => {
      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType,
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
        },
      });

      const error = new Error('boom');
      wrapper.findComponent(PresenterComponent).vm.$emit('error', error);

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });
  });

  describe('stat', () => {
    it('forwards displayConfig to the stat presenter', () => {
      const displayConfig = { title: 'Total suggestions' };

      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'stat',
          fields: MOCK_STAT_FIELDS,
          displayConfig,
        },
      });

      expect(wrapper.findComponent(StatPresenter).props('displayConfig')).toBe(displayConfig);
    });

    it('forwards the query data source to the stat presenter', () => {
      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'stat',
          fields: MOCK_STAT_FIELDS,
          source: 'CodeSuggestions',
        },
      });

      expect(wrapper.findComponent(StatPresenter).props('source')).toBe('CodeSuggestions');
    });

    it('forwards the comparison data to the stat presenter', () => {
      const comparisonData = { nodes: [{ totalCount: 4 }] };
      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: { nodes: [{ totalCount: 5 }] },
          comparisonData,
          displayType: 'stat',
          fields: MOCK_STAT_FIELDS,
        },
      });

      expect(wrapper.findComponent(StatPresenter).props('comparisonData')).toBe(comparisonData);
    });

    it('declares displayConfig, so it does not leak into the DOM as an attribute', () => {
      const wrapper = mountExtended(DataPresenter, {
        propsData: {
          data: { nodes: [{ totalCount: 5 }] },
          displayType: 'stat',
          fields: MOCK_STAT_FIELDS,
          displayConfig: { title: 'Total suggestions' },
        },
      });

      expect(wrapper.findComponent(StatPresenter).attributes('display-config')).toBeUndefined();
    });

    it('re-emits errors from the stat presenter', () => {
      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'stat',
          fields: MOCK_STAT_FIELDS,
        },
      });

      const error = new Error('boom');
      wrapper.findComponent(StatPresenter).vm.$emit('error', error);

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });
  });

  describe('bar list', () => {
    const createBarListWrapper = (propsData) =>
      shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'barList',
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
          ...propsData,
        },
      });

    it('forwards the comparison data to the bar list presenter', () => {
      const comparisonData = { nodes: [{ language: 'ruby', totalCount: 4 }] };

      const wrapper = createBarListWrapper({ comparisonData });

      expect(wrapper.findComponent(BarListPresenter).props('comparisonData')).toBe(comparisonData);
    });

    it('forwards the query data source to the bar list presenter', () => {
      const wrapper = createBarListWrapper({ source: 'CodeSuggestions' });

      expect(wrapper.findComponent(BarListPresenter).props('source')).toBe('CodeSuggestions');
    });
  });

  describe('table', () => {
    const createTableWrapper = (propsData) =>
      shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'table',
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
          ...propsData,
        },
      });

    it('forwards displayConfig to the table presenter', () => {
      const displayConfig = { description: 'Merged merge requests' };

      const wrapper = createTableWrapper({ displayConfig });

      expect(wrapper.findComponent(TablePresenter).props('displayConfig')).toBe(displayConfig);
    });

    it('joins the comparison data into the table presenter as a trend column', () => {
      const wrapper = createTableWrapper({
        comparisonData: MOCK_AGGREGATED_COMPARISON_DATA_ONE_DIM,
      });

      const tablePresenter = wrapper.findComponent(TablePresenter);

      expect(tablePresenter.props('fields').map(({ key }) => key)).toEqual([
        'language',
        'totalCount',
        '__trend',
      ]);
      expect(tablePresenter.props('data').nodes[0]).toMatchObject({
        language: 'ruby',
        __trendChange: 0.05,
      });
    });

    it('forwards the query data source to the table presenter', () => {
      const wrapper = createTableWrapper({ source: 'CodeSuggestions' });

      expect(wrapper.findComponent(TablePresenter).props('source')).toBe('CodeSuggestions');
    });

    it('re-emits errors from the table presenter', () => {
      const wrapper = createTableWrapper();

      const error = new Error('boom');
      wrapper.findComponent(TablePresenter).vm.$emit('error', error);

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });

    describe('trend column', () => {
      let wrapper;

      const createWrapper = async (propsData) => {
        wrapper = mountExtended(DataPresenter, {
          propsData: { displayType: 'table', ...propsData },
        });

        await nextTick();
      };

      const trendProps = {
        data: MOCK_AGGREGATED_DATA_ONE_DIM,
        comparisonData: MOCK_AGGREGATED_COMPARISON_DATA_ONE_DIM,
        fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
        source: 'CodeSuggestions',
      };

      // The resolver attaches the metric to the comparison result.
      const withTrendMetric = (props, metric) => ({
        ...props,
        comparisonData: { ...props.comparisonData, metric },
      });

      const headerLabels = () =>
        wrapper.findAllComponents(ThResizable).wrappers.map((th) => th.text());
      const badges = () => wrapper.findAllByTestId('trend-badge');
      const rowLabels = () =>
        wrapper.findAll('tbody tr').wrappers.map((row) => row.findAll('td').at(0).text());

      it('adds a column comparing against the previous period', async () => {
        await createWrapper(trendProps);

        expect(headerLabels()).toEqual(['Language', 'Total count', 'Total count trend']);
      });

      it('renders a badge describing how each row moved', async () => {
        await createWrapper(trendProps);

        expect(badges().wrappers.map((badge) => badge.text())).toEqual(['5%', '0%']);
      });

      it('colours and points the badge by the direction of the change', async () => {
        await createWrapper(trendProps);

        const [ruby, python] = badges().wrappers.map((badge) => badge.findComponent(GlBadge));

        expect(ruby.props()).toMatchObject({ variant: 'success', icon: 'arrow-up' });
        expect(python.props()).toMatchObject({ variant: 'neutral', icon: null });
      });

      it('spells the direction out in a tooltip, which the arrow and colour do not announce', async () => {
        await createWrapper(trendProps);

        expect(badges().at(0).attributes('title')).toBe('Up 5% from 20 in the previous period');
      });

      it('renders a skeleton cell for the trend column while loading', async () => {
        await createWrapper({ ...trendProps, loading: 2 });

        expect(wrapper.findAll('tbody tr').at(3).findAll('td')).toHaveLength(3);
      });

      describe('when a row has no counterpart in the previous period', () => {
        it('shows that the change is unknown rather than a badge', async () => {
          await createWrapper(trendProps);

          expect(rowLabels()).toEqual(['ruby', 'python', 'go']);
          expect(badges()).toHaveLength(2);
          expect(
            wrapper.findAllByTestId('trend-unknown').wrappers.map((cell) => cell.text()),
          ).toEqual(['\u2014']);
        });
      });

      describe('when there is no comparison data', () => {
        it('does not add the column', async () => {
          await createWrapper({ ...trendProps, comparisonData: null });

          expect(headerLabels()).toEqual(['Language', 'Total count']);
        });

        it('does not add the column when the previous period returned no rows', async () => {
          await createWrapper({ ...trendProps, comparisonData: { nodes: [] } });

          expect(headerLabels()).toEqual(['Language', 'Total count']);
        });
      });

      describe('while the comparison is still running', () => {
        const pendingProps = { ...trendProps, comparisonData: null, comparisonPending: true };

        it('reserves the column so it does not pop in later', async () => {
          await createWrapper(pendingProps);

          expect(headerLabels()).toEqual(['Language', 'Total count', 'Total count trend']);
        });

        // An em dash would read as "no counterpart in the previous period", which is not known yet.
        it('shows a skeleton in each trend cell rather than an unknown change', async () => {
          await createWrapper(pendingProps);

          expect(wrapper.findAllByTestId('trend-pending')).toHaveLength(3);
          expect(badges()).toHaveLength(0);
          expect(wrapper.findAllByTestId('trend-unknown')).toHaveLength(0);
        });

        it('resolves the metric from the name given up front when several are selected', async () => {
          await createWrapper({
            ...pendingProps,
            fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
            comparisonMetric: 'acceptanceRate',
          });

          expect(wrapper.emitted('error')).toBeUndefined();
          expect(headerLabels()).toContain('Acceptance rate trend');
        });

        it('reserves the column from the first paint, before any rows arrive', async () => {
          await createWrapper({ ...pendingProps, data: { nodes: [] }, loading: 2 });

          expect(headerLabels()).toEqual(['Language', 'Total count', 'Total count trend']);
          expect(wrapper.findAll('tbody tr').at(0).findAll('td')).toHaveLength(3);
        });

        // A comparison that fails or is dropped never lands, so reporting while pending would
        // flash an error that then disappears; the check waits for the result as it always has.
        it('waits for the comparison before reporting a missing trendMetric', async () => {
          await createWrapper({
            ...pendingProps,
            fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
          });

          expect(wrapper.emitted('error')).toBeUndefined();

          await wrapper.setProps({
            comparisonPending: false,
            comparisonData: trendProps.comparisonData,
          });

          expect(wrapper.emitted('error')[0][0].message).toBe(
            'table display type requires `trendMetric` when several metrics are selected',
          );
        });

        it('fills the cells once the comparison arrives', async () => {
          await createWrapper(pendingProps);
          await wrapper.setProps({
            comparisonPending: false,
            comparisonData: trendProps.comparisonData,
          });

          expect(wrapper.findAllByTestId('trend-pending')).toHaveLength(0);
          expect(badges().wrappers.map((badge) => badge.text())).toEqual(['5%', '0%']);
        });

        it('ignores a click on the reserved column header', async () => {
          await createWrapper(pendingProps);
          const firstCells = () =>
            wrapper.findAll('tbody tr td:first-child').wrappers.map((cell) => cell.text());
          const before = firstCells();

          await wrapper.findByTestId('column-2').trigger('click');

          expect(wrapper.findByTestId('column-2').findComponent(GlIcon).exists()).toBe(false);
          expect(firstCells()).toEqual(before);
        });
      });

      describe('when a dimension buckets by date', () => {
        it('does not add the column, because the buckets differ between periods', async () => {
          const mockWeeklyFields = [
            {
              key: 'created',
              label: 'Created',
              type: 'dimension',
              parameters: { granularity: 'weekly' },
            },
            { key: 'totalCount', label: 'Total count', type: 'metric' },
          ];

          await createWrapper({ ...trendProps, fields: mockWeeklyFields });

          expect(headerLabels()).toEqual(['Created (weekly)', 'Total count']);
        });
      });

      describe('when a dimension value cannot be identified', () => {
        beforeEach(async () => {
          await createWrapper({
            ...trendProps,
            data: MOCK_AGGREGATED_DATA_OBJECT_DIM,
            comparisonData: MOCK_AGGREGATED_DATA_OBJECT_DIM,
            fields: MOCK_AGGREGATED_FIELDS_OBJECT_DIM,
          });
        });

        it('still adds the column', () => {
          expect(headerLabels()).toEqual(['Group', 'Total count', 'Total count trend']);
        });

        it('shows every change as unknown rather than pairing rows on their label', () => {
          expect(badges()).toHaveLength(0);
          expect(wrapper.findAllByTestId('trend-unknown')).toHaveLength(2);
        });
      });

      describe('when a row is duplicated in the previous period', () => {
        beforeEach(async () => {
          const duplicated = MOCK_AGGREGATED_DATA_ONE_DIM.nodes[0];

          await createWrapper({
            ...trendProps,
            comparisonData: {
              nodes: [duplicated, duplicated, { language: 'python', totalCount: 7 }],
            },
          });
        });

        it('still adds the column', () => {
          expect(headerLabels()).toEqual(['Language', 'Total count', 'Total count trend']);
        });

        it('shows only the ambiguous row as unknown, since the rest still pair', () => {
          expect(rowLabels()).toEqual(['ruby', 'python', 'go']);
          expect(badges()).toHaveLength(1);
          expect(wrapper.findAllByTestId('trend-unknown')).toHaveLength(2);
        });
      });

      describe('when several metrics are selected', () => {
        const twoMetricProps = {
          ...trendProps,
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
        };

        it('reports an error when the panel does not say which to compare', async () => {
          await createWrapper(twoMetricProps);

          expect(wrapper.emitted('error')[0][0].message).toBe(
            'table display type requires `trendMetric` when several metrics are selected',
          );
        });

        it('compares the named metric', async () => {
          await createWrapper(withTrendMetric(twoMetricProps, 'acceptanceRate'));

          expect(badges().wrappers.map((badge) => badge.text())).toEqual(['25%', '16.8%']);
        });

        it('names the compared metric in the header', async () => {
          await createWrapper(withTrendMetric(twoMetricProps, 'acceptanceRate'));

          expect(headerLabels().at(-1)).toBe('Acceptance rate trend');
        });

        it('reports an error when the named metric is not selected', async () => {
          await createWrapper(withTrendMetric(twoMetricProps, 'usersCount'));

          expect(wrapper.emitted('error')[0][0].message).toBe(
            'Unknown metric for `trendMetric`: `usersCount`.',
          );
        });
      });

      describe('when the metric is aliased', () => {
        const mockAliasedFields = [
          { key: 'language', label: 'Language', type: 'dimension' },
          { key: 'Suggestions', label: 'Suggestions', field: 'totalCount', type: 'metric' },
          { key: 'acceptanceRate', label: 'Acceptance rate', type: 'metric' },
        ];
        const mockAliasedData = {
          nodes: [{ language: 'ruby', Suggestions: 21, acceptanceRate: 0.5 }],
        };
        const mockAliasedComparisonData = {
          nodes: [{ language: 'ruby', Suggestions: 20, acceptanceRate: 0.4 }],
        };

        it.each(['Suggestions', 'totalCount'])('resolves `%s` to the metric', async (metric) => {
          await createWrapper(
            withTrendMetric(
              {
                ...trendProps,
                data: mockAliasedData,
                comparisonData: mockAliasedComparisonData,
                fields: mockAliasedFields,
              },
              metric,
            ),
          );

          expect(badges().at(0).text()).toBe('5%');
        });
      });

      describe('when clicking the trend column header', () => {
        it('orders the rows by their change, with unknown changes last', async () => {
          await createWrapper(trendProps);

          await wrapper.findByTestId('column-2').trigger('click');

          expect(rowLabels()).toEqual(['python', 'ruby', 'go']);
        });

        it('marks the trend column as the sorted one', async () => {
          await createWrapper(trendProps);

          await wrapper.findByTestId('column-2').trigger('click');

          expect(wrapper.findByTestId('column-2').findComponent(GlIcon).props('name')).toBe(
            'arrow-up',
          );
        });
      });
    });
  });

  describe('lineChart', () => {
    it('re-emits errors from the line chart presenter', () => {
      const wrapper = shallowMountExtended(DataPresenter, {
        propsData: {
          data: MOCK_AGGREGATED_DATA_ONE_DIM,
          displayType: 'lineChart',
          fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
        },
      });

      const error = new Error('boom');
      wrapper.findComponent(LineChartPresenter).vm.$emit('error', error);

      expect(wrapper.emitted('error')).toEqual([[error]]);
    });
  });

  describe('unsupported display type', () => {
    let wrapper;

    beforeEach(() => {
      wrapper = shallowMountExtended(DataPresenter, {
        propsData: { data: MOCK_ISSUES, displayType: 'pieChart', fields: MOCK_FIELDS },
      });
    });

    it('emits an error listing the supported display types', () => {
      const [[error]] = wrapper.emitted('error');

      expect(error).toEqual(expect.any(Error));
      expect(error.message).toBe(
        'Unknown display type: `pieChart`. Supported display types are: ' +
          '`list`, `orderedList`, `table`, `stat`, `columnChart`, `lineChart`, `barChart`, ' +
          '`barList`, `areaChart`, `heatMap`, `divergingBarChart`.',
      );
    });

    it('does not render any presenter', () => {
      expect(wrapper.findComponent(ListPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(TablePresenter).exists()).toBe(false);
      expect(wrapper.findComponent(StatPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(ColumnChartPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(LineChartPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(BarChartPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(BarListPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(AreaChartPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(HeatMapPresenter).exists()).toBe(false);
      expect(wrapper.findComponent(DivergingBarChartPresenter).exists()).toBe(false);
    });
  });
});
