import { getUniquePanelId } from '~/vue_shared/components/customizable_dashboard/utils';

const cubeLineChart = {
  type: 'LineChart',
  slug: 'cube_line_chart',
  title: 'Cube line chart',
  data: {
    type: 'cube_analytics',
    query: {
      users: {
        measures: ['TrackedEvents.count'],
        dimensions: ['TrackedEvents.eventType'],
      },
    },
  },
  options: {
    xAxis: {
      name: 'Time',
      type: 'time',
    },
    yAxis: {
      name: 'Counts',
    },
  },
};

export const dashboard = {
  id: 'analytics_overview',
  slug: 'analytics_overview',
  title: 'Analytics Overview',
  description: 'This is a dashboard',
  userDefined: true,
  panels: [
    {
      title: 'Test A',
      gridAttributes: { width: 3, height: 3 },
      visualization: cubeLineChart,
      queryOverrides: null,
      id: getUniquePanelId(),
    },
    {
      title: 'Test B',
      gridAttributes: { width: 2, height: 4, minHeight: 2, minWidth: 2 },
      visualization: cubeLineChart,
      queryOverrides: {
        limit: 200,
      },
      id: getUniquePanelId(),
    },
  ],
  status: null,
  errors: null,
};

export const builtinDashboard = {
  title: 'Analytics Overview',
  description: 'This is a built-in description',
  panels: [
    {
      title: 'Test A',
      gridAttributes: { width: 3, height: 3 },
      visualization: cubeLineChart,
      queryOverrides: {},
      id: getUniquePanelId(),
    },
  ],
};

export const betaDashboard = {
  title: 'Test Dashboard',
  description: 'This dashboard is a work-in-progress',
  status: 'beta',
  panels: [
    {
      title: 'Test A',
      gridAttributes: { width: 3, height: 3 },
      visualization: cubeLineChart,
      queryOverrides: {},
      id: getUniquePanelId(),
    },
  ],
};

export const mockDateRangeFilterChangePayload = {
  startDate: new Date('2016-01-01'),
  endDate: new Date('2016-02-01'),
  dateRangeOption: 'foo',
};

export const mockPanel = {
  title: 'Test A',
  gridAttributes: {
    width: 1,
    height: 2,
    xPos: 0,
    yPos: 3,
    minWidth: 1,
    minHeight: 2,
    maxWidth: 1,
    maxHeight: 2,
  },
  visualization: cubeLineChart,
  queryOverrides: {},
  id: getUniquePanelId(),
};

export const TEST_VISUALIZATION = () => ({
  version: 1,
  type: 'LineChart',
  slug: 'test_visualization',
  data: {
    type: 'cube_analytics',
    query: {
      measures: ['TrackedEvents.count'],
      timeDimensions: [
        {
          dimension: 'TrackedEvents.utcTime',
          granularity: 'day',
        },
      ],
      limit: 100,
      timezone: 'UTC',
      filters: [],
      dimensions: [],
    },
  },
});

export const TEST_EMPTY_DASHBOARD_SVG_PATH = 'illustration/empty-state/empty-dashboard-md';

export const TEST_VISUALIZATIONS_GRAPHQL_SUCCESS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/73',
      customizableDashboardVisualizations: {
        nodes: [
          {
            slug: 'another_one',
            type: 'SingleStat',
            data: {
              type: 'cube_analytics',
              query: {
                measures: ['TrackedEvents.count'],
                filters: [
                  {
                    member: 'TrackedEvents.event',
                    operator: 'equals',
                    values: ['click'],
                  },
                ],
                limit: 100,
                timezone: 'UTC',
                dimensions: [],
                timeDimensions: [],
              },
            },
            options: {},
            __typename: 'CustomizableDashboardVisualization',
          },
        ],
      },
    },
  },
};

export const TEST_CUSTOM_DASHBOARDS_PROJECT = {
  fullPath: 'test/test-dashboards',
  id: 123,
  name: 'test-dashboards',
  defaultBranch: 'some-branch',
};

export const getGraphQLDashboard = (options = {}, withPanels = true) => {
  const newDashboard = {
    slug: '',
    title: '',
    userDefined: false,
    status: null,
    description: 'Understand your audience',
    __typename: 'CustomizableDashboard',
    errors: [],
    ...options,
  };

  if (withPanels) {
    return {
      ...newDashboard,
      panels: {
        nodes: [
          {
            title: 'Daily Active Users',
            gridAttributes: {
              yPos: 1,
              xPos: 0,
              width: 6,
              height: 5,
            },
            queryOverrides: {
              limit: 200,
            },
            visualization: {
              slug: 'line_chart',
              type: 'LineChart',
              options: {
                xAxis: {
                  name: 'Time',
                  type: 'time',
                },
                yAxis: {
                  name: 'Counts',
                  type: 'time',
                },
              },
              data: {
                type: 'cube_analytics',
                query: {
                  measures: ['TrackedEvents.uniqueUsersCount'],
                  timeDimensions: [
                    {
                      dimension: 'TrackedEvents.derivedTstamp',
                      granularity: 'day',
                    },
                  ],
                  limit: 100,
                  timezone: 'UTC',
                  filters: [],
                  dimensions: [],
                },
              },
              errors: null,
              __typename: 'CustomizableDashboardVisualization',
            },
            __typename: 'CustomizableDashboardPanel',
          },
        ],
        __typename: 'CustomizableDashboardPanelConnection',
      },
    };
  }

  return newDashboard;
};

export const TEST_ALL_DASHBOARDS_GRAPHQL_SUCCESS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      customizableDashboards: {
        nodes: [
          getGraphQLDashboard({ slug: 'audience', title: 'Audience' }, false),
          getGraphQLDashboard({ slug: 'behavior', title: 'Behavior' }, false),
          getGraphQLDashboard(
            { slug: 'new_dashboard', title: 'new_dashboard', userDefined: true },
            false,
          ),
          getGraphQLDashboard(
            { slug: 'audience_copy', title: 'Audience (Copy)', userDefined: true },
            false,
          ),
        ],
        __typename: 'CustomizableDashboardConnection',
      },
      __typename: 'Project',
    },
  },
};

export const TEST_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      customizableDashboards: {
        nodes: [getGraphQLDashboard({ slug: 'audience', title: 'Audience' })],
        __typename: 'CustomizableDashboardConnection',
      },
      __typename: 'Project',
    },
  },
};

export const TEST_CUSTOM_DASHBOARD_GRAPHQL_SUCCESS_RESPONSE = {
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      customizableDashboards: {
        nodes: [
          getGraphQLDashboard({
            slug: 'custom_dashboard',
            title: 'Custom Dashboard',
            userDefined: true,
          }),
        ],
        __typename: 'CustomizableDashboardConnection',
      },
      __typename: 'Project',
    },
  },
};
