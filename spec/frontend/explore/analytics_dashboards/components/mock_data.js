export const mockEmptyDashboardsListResponse = {
  customDashboards: {
    nodes: [],
  },
};

export const mockDashboardsListResponse = {
  customDashboards: {
    nodes: [
      {
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
        __typename: 'CustomDashboard',
      },
    ],
  },
};
