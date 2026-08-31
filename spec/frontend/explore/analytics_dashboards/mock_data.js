export const mockEmptyDashboardsListResponse = {
  customDashboards: {
    nodes: [],
  },
};

// Shape returned when the query is unauthorized, e.g. the `custom_dashboard_storage`
// feature flag is disabled: the field resolves to null rather than an empty list.
export const mockNullDashboardsListResponse = {
  customDashboards: null,
};

export const mockCustomDashboard = {
  id: 'gid://gitlab/Analytics::CustomDashboards::Dashboard/3',
  name: 'Fake trends',
  description: 'Visualize fake trend data that is definitly fake',
  config: {
    title: 'Fake trend dashboard',
    panels: [
      {
        title: 'Total fake users',
        visualization: 'fake_users_count_over_time',
        gridAttributes: {
          xPos: 0,
          yPos: 0,
          width: 3,
          height: 1,
        },
      },
      {
        title: 'Some arbritrary attribute',
        options: {},
        visualization: 'fake_attribute_count_over_time',
        gridAttributes: {
          xPos: 3,
          yPos: 0,
          width: 3,
          height: 1,
        },
      },
    ],
    version: '2',
    description: 'A very much more specific description',
  },
  organization: {
    id: 'gid://gitlab/Organizations::Organization/1',
    name: 'Fake organization',
    __typename: 'Organization',
  },
  namespace: null,
  createdBy: {
    id: 'gid://gitlab/User/1',
    name: 'Administrator',
    username: 'root',
    webUrl: 'http://gdk.test:3001/root',
    webPath: '/root',
    avatarUrl: 'https://www.gravatar.com/avatar/fake',
    __typename: 'UserCore',
  },
  createdAt: '2026-03-25T04:38:01Z',
  updatedAt: '2026-03-25T04:38:01Z',
  system: false,
  slug: null,
  __typename: 'CustomDashboard',
};

export const mockSystemDashboard = {
  id: 'gitlab:dashboard:merge_requests',
  name: 'Merge request analytics',
  description: 'Get insights into your merge request lifecycle and view trends over time.',
  config: {
    title: 'Merge request analytics',
    panels: [],
    version: '2',
  },
  createdAt: null,
  system: true,
  slug: 'merge_requests',
  __typename: 'CustomSystemDashboard',
};

export const mockDashboardsListResponse = {
  customDashboards: {
    nodes: [mockCustomDashboard, mockSystemDashboard],
  },
};

export const mockDashboardResponse = {
  customDashboard: mockCustomDashboard,
};

export const mockSystemDashboardResponse = {
  customSystemDashboard: mockSystemDashboard,
};

export const mockDashboardCompactGridResponse = {
  customDashboard: {
    ...mockCustomDashboard,
    config: {
      ...mockCustomDashboard.config,
      gridHeight: 'COMPACT',
    },
  },
};

export const mockDashboardWithViews = {
  ...mockCustomDashboard,
  config: {
    ...mockCustomDashboard.config,
    views: [
      {
        title: 'Overview',
        panels: [
          {
            title: 'Overview panel',
            visualization: 'overview_over_time',
            gridAttributes: { xPos: 0, yPos: 0, width: 3, height: 1 },
          },
        ],
      },
      {
        title: 'Details',
        panels: [
          {
            title: 'Details panel one',
            visualization: 'details_one_over_time',
            gridAttributes: { xPos: 0, yPos: 0, width: 3, height: 1 },
          },
          {
            title: 'Details panel two',
            visualization: 'details_two_over_time',
            gridAttributes: { xPos: 3, yPos: 0, width: 3, height: 1 },
          },
        ],
      },
    ],
  },
};

export const mockDashboardWithViewsResponse = {
  customDashboard: mockDashboardWithViews,
};

export const mockPanelWithViews = {
  ...mockCustomDashboard.config.panels[0],
  titleIcon: 'information-o',
  tooltip: { description: 'Fake tooltip' },
  queryOverrides: { limit: 10 },
  // The explore app expects an inline visualization object, not a slug.
  visualization: { type: 'SingleStat' },
  views: [
    { text: 'Chart', visualization: { type: 'LineChart' } },
    { text: 'Table', visualization: { type: 'DataTable' } },
  ],
};

export const mockDashboardWithPanelViews = {
  ...mockCustomDashboard,
  config: {
    ...mockCustomDashboard.config,
    panels: [mockPanelWithViews],
  },
};

export const mockDashboardWithPanelViewsResponse = {
  customDashboard: mockDashboardWithPanelViews,
};
