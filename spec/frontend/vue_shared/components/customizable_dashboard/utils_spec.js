import getCustomizableDashboardQuery from '~/vue_shared/components/customizable_dashboard/graphql/queries/get_customizable_dashboard.query.graphql';
import getAllCustomizableDashboardsQuery from '~/vue_shared/components/customizable_dashboard/graphql/queries/get_all_customizable_dashboards.query.graphql';
import {
  buildDefaultDashboardFilters,
  dateRangeOptionToFilter,
  filtersToQueryParams,
  getDateRangeOption,
  isEmptyPanelData,
  availableVisualizationsValidator,
  getDashboardConfig,
  updateApolloCache,
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
import { createMockClient } from 'helpers/mock_apollo_helper';
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
  TEST_VISUALIZATION,
  TEST_CUSTOM_DASHBOARDS_PROJECT,
  TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE,
  getGraphQLDashboard,
  TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE,
  TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE,
} from './mock_data';

const option = DATE_RANGE_OPTIONS[0];

describe('#createNewVisualizationPanel', () => {
  it('returns the expected object', () => {
    const visualization = TEST_VISUALIZATION();
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
          visualization: 'cube_line_chart',
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
          visualization: 'cube_line_chart',
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

describe('updateApolloCache', () => {
  let apolloClient;
  let mockReadQuery;
  let mockWriteQuery;
  const dashboardSlug = 'analytics_overview';
  const { fullPath } = TEST_CUSTOM_DASHBOARDS_PROJECT;
  const isProject = true;

  const setMockCache = (mockDashboardDetails, mockDashboardsList) => {
    mockReadQuery.mockImplementation(({ query }) => {
      if (query === getCustomizableDashboardQuery) {
        return mockDashboardDetails;
      }
      if (query === getAllCustomizableDashboardsQuery) {
        return mockDashboardsList;
      }

      return null;
    });
  };

  beforeEach(() => {
    apolloClient = createMockClient();

    mockReadQuery = jest.fn();
    mockWriteQuery = jest.fn();
    apolloClient.readQuery = mockReadQuery;
    apolloClient.writeQuery = mockWriteQuery;
  });

  describe('dashboard details cache', () => {
    it('updates an existing dashboard', () => {
      const existingDashboard = getGraphQLDashboard(
        {
          slug: 'some_existing_dash',
          title: 'some existing title',
        },
        false,
      );
      const existingDetailsCache = {
        ...TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE.data,
      };
      existingDetailsCache.project.customizableDashboards.nodes = [existingDashboard];

      setMockCache(existingDetailsCache, null);

      updateApolloCache({
        apolloClient,
        slug: existingDashboard.slug,
        dashboard: {
          ...existingDashboard,
          title: 'some new title',
        },
        fullPath,
        isProject,
      });

      expect(mockWriteQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          query: getCustomizableDashboardQuery,
          data: expect.objectContaining({
            project: expect.objectContaining({
              customizableDashboards: expect.objectContaining({
                nodes: expect.arrayContaining([
                  expect.objectContaining({
                    title: 'some new title',
                  }),
                ]),
              }),
            }),
          }),
        }),
      );
    });

    it('does not update for new dashboards where cache is empty', () => {
      setMockCache(null, TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE.data);

      updateApolloCache({
        apolloClient,
        slug: dashboardSlug,
        dashboard,
        fullPath,
        isProject,
      });

      expect(mockWriteQuery).not.toHaveBeenCalledWith(
        expect.objectContaining({ query: getCustomizableDashboardQuery }),
      );
    });
  });

  describe('dashboards list', () => {
    it('adds a new dashboard to the dashboards list', () => {
      setMockCache(null, TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE.data);

      updateApolloCache({
        apolloClient,
        slug: dashboardSlug,
        dashboard,
        fullPath,
        isProject,
      });

      expect(mockWriteQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          query: getAllCustomizableDashboardsQuery,
          data: expect.objectContaining({
            project: expect.objectContaining({
              customizableDashboards: expect.objectContaining({
                nodes: expect.arrayContaining([
                  expect.objectContaining({
                    slug: dashboardSlug,
                  }),
                ]),
              }),
            }),
          }),
        }),
      );
    });

    it('updates an existing dashboard on the dashboards list', () => {
      setMockCache(null, TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE.data);

      const existingDashboards =
        TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE.data.project.customizableDashboards.nodes;

      const updatedDashboard = {
        ...existingDashboards.at(0),
        title: 'some new title',
      };

      updateApolloCache({
        apolloClient,
        slug: dashboardSlug,
        dashboard: updatedDashboard,
        fullPath,
        isProject,
      });

      expect(mockWriteQuery).toHaveBeenCalledWith(
        expect.objectContaining({
          query: getAllCustomizableDashboardsQuery,
          data: expect.objectContaining({
            project: expect.objectContaining({
              customizableDashboards: expect.objectContaining({
                nodes: expect.arrayContaining([
                  expect.objectContaining({
                    title: 'some new title',
                  }),
                ]),
              }),
            }),
          }),
        }),
      );
    });

    it('does not update dashboard list cache when it has not yet been populated', () => {
      setMockCache(TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE.data, null);

      updateApolloCache({
        apolloClient,
        slug: dashboardSlug,
        dashboard,
        fullPath,
        isProject,
      });

      expect(mockWriteQuery).not.toHaveBeenCalledWith(
        expect.objectContaining({ query: getAllCustomizableDashboardsQuery }),
      );
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
