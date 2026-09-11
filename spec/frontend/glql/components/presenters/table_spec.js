import { nextTick } from 'vue';
import { GlBadge, GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ThResizable from '~/glql/components/common/th_resizable.vue';
import FieldPresenter from '~/glql/components/presenters/field.vue';
import IssuablePresenter from '~/glql/components/presenters/issuable.vue';
import ProjectPresenter from '~/glql/components/presenters/project.vue';
import StatePresenter from '~/glql/components/presenters/state.vue';
import TablePresenter from '~/glql/components/presenters/table.vue';
import HtmlPresenter from '~/glql/components/presenters/html.vue';
import UserPresenter from '~/glql/components/presenters/user.vue';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';
import {
  MOCK_AGGREGATED_COMPARISON_DATA_ONE_DIM,
  MOCK_AGGREGATED_DATA_OBJECT_DIM,
  MOCK_AGGREGATED_DATA_ONE_DIM,
  MOCK_AGGREGATED_FIELDS_OBJECT_DIM,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
  MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
  MOCK_FIELDS,
  MOCK_ISSUES,
  MOCK_PROJECT,
} from '../../mock_data';

describe('TablePresenter', () => {
  let wrapper;

  useMockLocationHelper();

  beforeEach(() => {
    window.location.href = 'https://gitlab.com/gitlab-org/gitlab-shell/-/issues/1';
    window.location.origin = 'https://gitlab.com';
  });

  const createWrapper = async ({ data, fields, ...moreProps }, mountFn = shallowMountExtended) => {
    wrapper = mountFn(TablePresenter, {
      propsData: { data, fields, ...moreProps },
    });

    await nextTick();
  };

  const getCells = (row) => row.findAll('td').wrappers.map((td) => td.text());

  it('renders header rows with sentence cased field names', async () => {
    await createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS });

    const headerCells = wrapper.findAllComponents(ThResizable).wrappers.map((th) => th.text());

    expect(headerCells).toEqual(['Title', 'Author', 'State', 'Description']);
  });

  it('renders header rows with granularity when fields have parameters', async () => {
    const fieldsWithGranularity = [
      {
        key: 'finished',
        label: 'Finished',
        name: 'finishedAt',
        type: 'dimension',
        parameters: { granularity: 'weekly' },
      },
      { key: 'totalCount', label: 'Total count', name: 'totalCount', type: 'metric' },
    ];

    await createWrapper({ data: { nodes: [] }, fields: fieldsWithGranularity });

    const headerCells = wrapper.findAllComponents(ThResizable).wrappers.map((th) => th.text());

    expect(headerCells).toEqual(['Finished (weekly)', 'Total count']);
  });

  it('renders the alias label without the granularity suffix for aliased fields', async () => {
    const aliasedTimeDimension = {
      key: 'foo',
      field: 'created',
      label: 'foo',
      name: 'createdAt',
      type: 'dimension',
      parameters: { granularity: 'weekly' },
    };

    await createWrapper({ data: { nodes: [] }, fields: [aliasedTimeDimension] });

    const headerCells = wrapper.findAllComponents(ThResizable).wrappers.map((th) => th.text());

    expect(headerCells).toEqual(['foo']);
  });

  it('passes field key for data access and presenter key for dispatch on aliased fields', async () => {
    const aliasedField = {
      key: 'p50',
      field: 'durationQuantile',
      label: 'Duration P50',
      type: 'metric',
      parameters: { quantile: 0.5 },
    };

    await createWrapper({
      data: { nodes: [{ p50: 3661 }] },
      fields: [aliasedField],
    });

    const fieldPresenter = wrapper.findComponent(FieldPresenter);
    expect(fieldPresenter.props('fieldKey')).toBe('p50');
    expect(fieldPresenter.props('presenterKey')).toBe('durationQuantile');
  });

  it('renders formatted values, not "None", for aliased parameterised fields', async () => {
    const fields = [
      {
        key: 'Monthly',
        field: 'timestamp',
        label: 'Monthly',
        name: 'timestamp',
        type: 'dimension',
        parameters: { granularity: 'monthly' },
      },
      {
        key: 'p50',
        field: 'durationQuantile',
        label: 'Duration P50',
        name: 'durationQuantile',
        type: 'metric',
        parameters: { quantile: 0.5 },
      },
    ];

    await createWrapper(
      { data: { nodes: [{ id: '1', Monthly: '2026-06-01', p50: 3661 }] }, fields },
      mountExtended,
    );

    const cells = getCells(wrapper.findByTestId('table-row-0'));

    expect(cells).toEqual(['Jun 1, 2026', '1h 1m 1s']);
  });

  it('renders skeleton loader if loading is true', () => {
    createWrapper({ data: { nodes: [] }, fields: MOCK_FIELDS, loading: true }, mountExtended);

    // 5 rows of 4 columns each
    expect(wrapper.findAllComponents(GlSkeletonLoader)).toHaveLength(20);
  });

  it('renders a row of items presented by appropriate presenters', async () => {
    await createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS }, mountExtended);

    const tableRow1 = wrapper.findByTestId('table-row-0');
    const tableRow2 = wrapper.findByTestId('table-row-1');

    const issuePresenter1 = tableRow1.findComponent(IssuablePresenter);
    const issuePresenter2 = tableRow2.findComponent(IssuablePresenter);
    const userPresenter1 = tableRow1.findComponent(UserPresenter);
    const userPresenter2 = tableRow2.findComponent(UserPresenter);
    const statePresenter1 = tableRow1.findComponent(StatePresenter);
    const statePresenter2 = tableRow2.findComponent(StatePresenter);
    const htmlPresenter1 = tableRow1.findComponent(HtmlPresenter);
    const htmlPresenter2 = tableRow2.findComponent(HtmlPresenter);

    expect(issuePresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0]);
    expect(issuePresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1]);
    expect(userPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].author);
    expect(userPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].author);
    expect(statePresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].state);
    expect(statePresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].state);
    expect(htmlPresenter1.props('data')).toBe(MOCK_ISSUES.nodes[0].description);
    expect(htmlPresenter2.props('data')).toBe(MOCK_ISSUES.nodes[1].description);

    expect(getCells(tableRow1)).toEqual([
      'Issue 1 (gitlab-test#1)',
      '@foobar',
      'Open',
      'This is a description',
    ]);
    expect(getCells(tableRow2)).toEqual([
      'Issue 2 (gitlab-test#2 - closed)',
      '@janedoe',
      'Closed',
      'This is another description',
    ]);
  });

  it('routes the title-aliased field of a Project row through ProjectPresenter', async () => {
    await createWrapper(
      {
        data: { nodes: [{ ...MOCK_PROJECT, id: 'gid://gitlab/Project/1', name: 'Wget2' }] },
        fields: [{ key: 'name', label: 'Name', name: 'name' }],
      },
      mountExtended,
    );

    const row = wrapper.findByTestId('table-row-0');
    expect(row.findComponent(ProjectPresenter).exists()).toBe(true);
  });

  const order0 = [
    ['Issue 1 (gitlab-test#1)', '@foobar', 'Open', 'This is a description'],
    ['Issue 2 (gitlab-test#2 - closed)', '@janedoe', 'Closed', 'This is another description'],
  ];

  const order1 = [
    ['Issue 2 (gitlab-test#2 - closed)', '@janedoe', 'Closed', 'This is another description'],
    ['Issue 1 (gitlab-test#1)', '@foobar', 'Open', 'This is a description'],
  ];

  describe.each`
    cellIndex | headerTitle      | orderAsc  | orderDesc
    ${0}      | ${'title'}       | ${order0} | ${order1}
    ${1}      | ${'author'}      | ${order0} | ${order1}
    ${2}      | ${'state'}       | ${order0} | ${order1}
    ${3}      | ${'description'} | ${order0} | ${order1}
  `('when clicking on header cell at index $cellIndex', ({ cellIndex, orderAsc, orderDesc }) => {
    let actualOrder;

    const triggerClick = async () => {
      await nextTick();
      await wrapper.findByTestId(`column-${cellIndex}`).trigger('click');

      actualOrder = wrapper.findAll('tbody tr').wrappers.map(getCells);
    };

    beforeEach(async () => {
      await createWrapper({ data: MOCK_ISSUES, fields: MOCK_FIELDS }, mountExtended);

      await triggerClick();
    });

    describe('once', () => {
      it('sorts the table by the field in ascending order', () => {
        expect(actualOrder).toEqual(orderAsc);
      });

      it('shows an arrow-up icon on the sorted column', () => {
        const icon = wrapper.findByTestId(`column-${cellIndex}`).findComponent(GlIcon);

        expect(icon.props('name')).toBe('arrow-up');
      });

      it('does not show a sort icon on other columns', () => {
        const otherColumns = MOCK_FIELDS.filter((_, i) => i !== cellIndex);

        otherColumns.forEach((_, i) => {
          const colIndex = i >= cellIndex ? i + 1 : i;
          const icon = wrapper.findByTestId(`column-${colIndex}`).findComponent(GlIcon);

          expect(icon.exists()).toBe(false);
        });
      });
    });

    describe('twice', () => {
      beforeEach(async () => {
        await triggerClick();
      });

      it('sorts the table by the field in descending order', () => {
        expect(actualOrder).toEqual(orderDesc);
      });

      it('shows an arrow-down icon on the sorted column', () => {
        const icon = wrapper.findByTestId(`column-${cellIndex}`).findComponent(GlIcon);

        expect(icon.props('name')).toBe('arrow-down');
      });
    });
  });

  describe('when sorting by an aliased column', () => {
    const aliasedField = {
      key: 'p50',
      field: 'durationQuantile',
      label: 'Duration P50',
      type: 'metric',
      parameters: { quantile: 0.5 },
    };

    beforeEach(async () => {
      await createWrapper(
        {
          data: {
            nodes: [
              { id: '1', p50: 7200 },
              { id: '2', p50: 3600 },
            ],
          },
          fields: [aliasedField],
        },
        mountExtended,
      );

      await wrapper.findByTestId('column-0').trigger('click');
    });

    it('reorders the rows by the alias key in ascending order', () => {
      const actualOrder = wrapper.findAll('tbody tr').wrappers.map(getCells);

      expect(actualOrder).toEqual([['1h'], ['2h']]);
    });

    it('shows an arrow-up icon on the sorted column', () => {
      const icon = wrapper.findByTestId('column-0').findComponent(GlIcon);

      expect(icon.props('name')).toBe('arrow-up');
    });

    it('reorders the rows in descending order on a second click', async () => {
      await wrapper.findByTestId('column-0').trigger('click');

      const actualOrder = wrapper.findAll('tbody tr').wrappers.map(getCells);

      expect(actualOrder).toEqual([['2h'], ['1h']]);
      expect(wrapper.findByTestId('column-0').findComponent(GlIcon).props('name')).toBe(
        'arrow-down',
      );
    });
  });

  describe('trend column', () => {
    const trendProps = {
      data: MOCK_AGGREGATED_DATA_ONE_DIM,
      comparisonData: MOCK_AGGREGATED_COMPARISON_DATA_ONE_DIM,
      fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_ONE_METRIC,
      source: 'CodeSuggestions',
    };

    const headerLabels = () =>
      wrapper.findAllComponents(ThResizable).wrappers.map((th) => th.text());
    const badges = () => wrapper.findAllByTestId('trend-badge');
    const rowLabels = () =>
      wrapper.findAll('tbody tr').wrappers.map((row) => row.findAll('td').at(0).text());

    it('adds a column comparing against the previous period', async () => {
      await createWrapper(trendProps, mountExtended);

      expect(headerLabels()).toEqual(['Language', 'Total count', 'vs previous period']);
    });

    it('renders a badge describing how each row moved', async () => {
      await createWrapper(trendProps, mountExtended);

      expect(badges().wrappers.map((badge) => badge.text())).toEqual(['5%', '0%']);
    });

    it('colours and points the badge by the direction of the change', async () => {
      await createWrapper(trendProps, mountExtended);

      const [ruby, python] = badges().wrappers.map((badge) => badge.findComponent(GlBadge));

      expect(ruby.props()).toMatchObject({ variant: 'success', icon: 'arrow-up' });
      expect(python.props()).toMatchObject({ variant: 'neutral', icon: null });
    });

    it('spells the direction out in a tooltip, which the arrow and colour do not announce', async () => {
      await createWrapper(trendProps, mountExtended);

      expect(badges().at(0).attributes('title')).toBe('Up 5% from 20 in the previous period');
    });

    it('renders a skeleton cell for the trend column while loading', async () => {
      await createWrapper({ ...trendProps, loading: 2 }, mountExtended);

      expect(wrapper.findAll('tbody tr').at(3).findAll('td')).toHaveLength(3);
    });

    describe('when a row has no counterpart in the previous period', () => {
      it('shows that the change is unknown rather than a badge', async () => {
        await createWrapper(trendProps, mountExtended);

        expect(rowLabels()).toEqual(['ruby', 'python', 'go']);
        expect(badges()).toHaveLength(2);
        expect(
          wrapper.findAllByTestId('trend-unknown').wrappers.map((cell) => cell.text()),
        ).toEqual(['\u2014']);
      });
    });

    describe('when there is no comparison data', () => {
      it('does not add the column', async () => {
        await createWrapper({ ...trendProps, comparisonData: null }, mountExtended);

        expect(headerLabels()).toEqual(['Language', 'Total count']);
      });

      it('does not add the column when the previous period returned no rows', async () => {
        await createWrapper({ ...trendProps, comparisonData: { nodes: [] } }, mountExtended);

        expect(headerLabels()).toEqual(['Language', 'Total count']);
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

        await createWrapper({ ...trendProps, fields: mockWeeklyFields }, mountExtended);

        expect(headerLabels()).toEqual(['Created (weekly)', 'Total count']);
      });
    });

    describe('when a dimension value cannot be identified', () => {
      beforeEach(async () => {
        await createWrapper(
          {
            ...trendProps,
            data: MOCK_AGGREGATED_DATA_OBJECT_DIM,
            comparisonData: MOCK_AGGREGATED_DATA_OBJECT_DIM,
            fields: MOCK_AGGREGATED_FIELDS_OBJECT_DIM,
          },
          mountExtended,
        );
      });

      it('still adds the column', () => {
        expect(headerLabels()).toEqual(['Group', 'Total count', 'vs previous period']);
      });

      it('shows every change as unknown rather than pairing rows on their label', () => {
        expect(badges()).toHaveLength(0);
        expect(wrapper.findAllByTestId('trend-unknown')).toHaveLength(2);
      });
    });

    describe('when a row is duplicated in the previous period', () => {
      it('does not add the column, because either pairing would be a guess', async () => {
        const duplicated = MOCK_AGGREGATED_DATA_ONE_DIM.nodes[0];

        await createWrapper(
          { ...trendProps, comparisonData: { nodes: [duplicated, duplicated] } },
          mountExtended,
        );

        expect(headerLabels()).toEqual(['Language', 'Total count']);
      });
    });

    describe('when several metrics are selected', () => {
      const twoMetricProps = {
        ...trendProps,
        fields: MOCK_AGGREGATED_FIELDS_ONE_DIM_TWO_METRICS,
      };

      it('reports an error when the panel does not say which to compare', async () => {
        await createWrapper(twoMetricProps, mountExtended);

        expect(wrapper.emitted('error')[0][0].message).toBe(
          'table display type requires `trendMetric` when several metrics are selected',
        );
      });

      it('compares the named metric', async () => {
        await createWrapper({ ...twoMetricProps, trendMetric: 'acceptanceRate' }, mountExtended);

        expect(badges().wrappers.map((badge) => badge.text())).toEqual(['25%', '16.8%']);
      });

      it('reports an error when the named metric is not selected', async () => {
        await createWrapper({ ...twoMetricProps, trendMetric: 'usersCount' }, mountExtended);

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

      it.each(['Suggestions', 'totalCount'])('resolves `%s` to the metric', async (trendMetric) => {
        await createWrapper(
          {
            ...trendProps,
            data: mockAliasedData,
            comparisonData: mockAliasedComparisonData,
            fields: mockAliasedFields,
            trendMetric,
          },
          mountExtended,
        );

        expect(badges().at(0).text()).toBe('5%');
      });
    });

    describe('when clicking the trend column header', () => {
      it('orders the rows by their change, with unknown changes last', async () => {
        await createWrapper(trendProps, mountExtended);

        await wrapper.findByTestId('column-2').trigger('click');

        expect(rowLabels()).toEqual(['python', 'ruby', 'go']);
      });
    });
  });
});
