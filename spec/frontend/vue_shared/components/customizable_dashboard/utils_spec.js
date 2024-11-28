import {
  buildDefaultDashboardFilters,
  dateRangeOptionToFilter,
  filtersToQueryParams,
  getDateRangeOption,
  isEmptyPanelData,
  availableVisualizationsValidator,
  getDashboardConfig,
  getVisualizationCategory,
  parsePanelToGridItem,
  createNewVisualizationPanel,
} from '~/vue_shared/components/customizable_dashboard/utils';
import { newDate } from '~/lib/utils/datetime_utility';
import {
  CUSTOM_DATE_RANGE_KEY,
  DATE_RANGE_OPTIONS,
  DEFAULT_SELECTED_OPTION_INDEX,
} from '~/vue_shared/components/customizable_dashboard/filters/constants';
import {
  CATEGORY_SINGLE_STATS,
  CATEGORY_CHARTS,
  CATEGORY_TABLES,
  DASHBOARD_SCHEMA_VERSION,
} from '~/vue_shared/components/customizable_dashboard/constants';

import {
  mockDateRangeFilterChangePayload,
  dashboard,
  mockPanel,
  createVisualization,
} from './mock_data';

const option = DATE_RANGE_OPTIONS[0];

describe('#createNewVisualizationPanel', () => {
  it('returns the expected object', () => {
    const visualization = createVisualization();
    expect(createNewVisualizationPanel(visualization)).toMatchObject({
      visualization: {
        ...visualization,
        errors: null,
      },
      title: 'Test visualization',
      gridAttributes: {
        width: 4,
        height: 3,
      },
      options: {},
    });
  });
});

describe('getDateRangeOption', () => {
  it('should return the date range option', () => {
    expect(getDateRangeOption(option.key)).toStrictEqual(option);
  });
});

describe('dateRangeOptionToFilter', () => {
  it('filters data by `name` for the provided search term', () => {
    expect(dateRangeOptionToFilter(option)).toStrictEqual({
      startDate: option.startDate,
      endDate: option.endDate,
      dateRangeOption: option.key,
    });
  });
});

describe('buildDefaultDashboardFilters', () => {
  it('returns the default option for an empty query string', () => {
    const defaultOption = DATE_RANGE_OPTIONS[DEFAULT_SELECTED_OPTION_INDEX];

    expect(buildDefaultDashboardFilters('')).toStrictEqual({
      startDate: defaultOption.startDate,
      endDate: defaultOption.endDate,
      dateRangeOption: defaultOption.key,
      filterAnonUsers: false,
    });
  });

  it('returns the option that matches the date_range_option', () => {
    const queryString = `date_range_option=${option.key}`;

    expect(buildDefaultDashboardFilters(queryString)).toStrictEqual({
      startDate: option.startDate,
      endDate: option.endDate,
      dateRangeOption: option.key,
      filterAnonUsers: false,
    });
  });

  it('returns the a custom range when the query string is custom and contains dates', () => {
    const queryString = `date_range_option=${CUSTOM_DATE_RANGE_KEY}&start_date=2023-01-10&end_date=2023-02-08`;

    expect(buildDefaultDashboardFilters(queryString)).toStrictEqual({
      startDate: newDate('2023-01-10'),
      endDate: newDate('2023-02-08'),
      dateRangeOption: CUSTOM_DATE_RANGE_KEY,
      filterAnonUsers: false,
    });
  });

  it('returns the option that matches the date_range_option and ignores the query dates when the option is not custom', () => {
    const queryString = `date_range_option=${option.key}&start_date=2023-01-10&end_date=2023-02-08`;

    expect(buildDefaultDashboardFilters(queryString)).toStrictEqual({
      startDate: option.startDate,
      endDate: option.endDate,
      dateRangeOption: option.key,
      filterAnonUsers: false,
    });
  });

  it('returns "filterAnonUsers=true" when the query param for filtering out anonymous users is true', () => {
    const queryString = 'filter_anon_users=true';

    expect(buildDefaultDashboardFilters(queryString)).toMatchObject({
      filterAnonUsers: true,
    });
  });
});

describe('filtersToQueryParams', () => {
  const customOption = {
    ...mockDateRangeFilterChangePayload,
    dateRangeOption: CUSTOM_DATE_RANGE_KEY,
  };

  const nonCustomOption = {
    ...mockDateRangeFilterChangePayload,
    dateRangeOption: 'foobar',
  };

  it('returns the dateRangeOption with null date params when the option is not custom', () => {
    expect(filtersToQueryParams(nonCustomOption)).toStrictEqual({
      date_range_option: 'foobar',
      end_date: null,
      start_date: null,
      filter_anon_users: null,
    });
  });

  it('returns the dateRangeOption and date params when the option is custom', () => {
    expect(filtersToQueryParams(customOption)).toStrictEqual({
      date_range_option: CUSTOM_DATE_RANGE_KEY,
      start_date: '2016-01-01',
      end_date: '2016-02-01',
      filter_anon_users: null,
    });
  });

  it('returns "filter_anon_users=true" when filtering out anonymous users', () => {
    expect(filtersToQueryParams({ filterAnonUsers: true })).toMatchObject({
      filter_anon_users: true,
    });
  });
});

describe('isEmptyPanelData', () => {
  it.each`
    visualizationType | value  | expected
    ${'SingleStat'}   | ${[]}  | ${false}
    ${'SingleStat'}   | ${1}   | ${false}
    ${'LineChart'}    | ${[]}  | ${true}
    ${'LineChart'}    | ${[1]} | ${false}
  `(
    'returns $expected for visualization "$visualizationType" with value "$value"',
    ({ visualizationType, value, expected }) => {
      const result = isEmptyPanelData(visualizationType, value);
      expect(result).toBe(expected);
    },
  );
});

describe('availableVisualizationsValidator', () => {
  it('returns true when the object contains all properties', () => {
    const result = availableVisualizationsValidator({
      loading: false,
      hasError: false,
      visualizations: [],
    });
    expect(result).toBe(true);
  });

  it.each([
    { visualizations: [] },
    { hasError: false },
    { loading: true },
    { loading: true, hasError: false },
  ])('returns false when the object does not contain all properties', (testCase) => {
    const result = availableVisualizationsValidator(testCase);
    expect(result).toBe(false);
  });
});

describe('getDashboardConfig', () => {
  it('maps dashboard to expected value', () => {
    const result = getDashboardConfig(dashboard);

    expect(result).toMatchObject({
      id: 'analytics_overview',
      version: DASHBOARD_SCHEMA_VERSION,
      panels: [
        {
          gridAttributes: {
            height: 3,
            width: 3,
          },
          queryOverrides: {},
          title: 'Test A',
          visualization: 'test_visualization',
        },
        {
          gridAttributes: {
            height: 4,
            width: 2,
          },
          queryOverrides: {
            limit: 200,
          },
          title: 'Test B',
          visualization: 'test_visualization',
        },
      ],
      title: 'Analytics Overview',
      status: null,
      errors: null,
    });
  });

  ['userDefined', 'slug'].forEach((omitted) => {
    it(`omits "${omitted}" dashboard property`, () => {
      const result = getDashboardConfig(dashboard);

      expect(result[omitted]).not.toBeDefined();
    });
  });
});

describe('getVisualizationCategory', () => {
  it.each`
    category                 | type
    ${CATEGORY_SINGLE_STATS} | ${'SingleStat'}
    ${CATEGORY_TABLES}       | ${'DataTable'}
    ${CATEGORY_CHARTS}       | ${'LineChart'}
    ${CATEGORY_CHARTS}       | ${'FooBar'}
  `('returns $category when the visualization type is $type', ({ category, type }) => {
    expect(getVisualizationCategory({ type })).toBe(category);
  });
});

describe('parsePanelToGridItem', () => {
  it('parses all panel configs to GridStack format', () => {
    const { gridAttributes, ...rest } = mockPanel;

    expect(parsePanelToGridItem(mockPanel)).toStrictEqual({
      x: gridAttributes.xPos,
      y: gridAttributes.yPos,
      w: gridAttributes.width,
      h: gridAttributes.height,
      minH: gridAttributes.minHeight,
      minW: gridAttributes.minWidth,
      maxH: gridAttributes.maxHeight,
      maxW: gridAttributes.maxWidth,
      id: mockPanel.id,
      props: rest,
    });
  });

  it('filters out props with undefined values', () => {
    const local = { ...mockPanel };
    local.id = undefined;

    expect(Object.keys(parsePanelToGridItem(local))).not.toContain('id');
  });
});
