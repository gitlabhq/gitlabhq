export const mockGroupId = 'gid://gitlab/Group/1';

export const buildStatus = (id, name = `Status ${id}`) => ({
  __typename: 'WorkItemStatusCustom',
  id: `gid://gitlab/WorkItems::Statuses::Custom::Status/${id}`,
  name,
  iconName: 'status-waiting',
  color: '#737278',
  category: 'TO_DO',
});

export const mockStatus = buildStatus(1, 'To do');

export const mockAssignees = [
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    avatarUrl: '/avatar/1.png',
    name: 'Alice',
    username: 'alice',
    webUrl: '/alice',
    webPath: '/alice',
  },
  {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/2',
    avatarUrl: '/avatar/2.png',
    name: 'Bob',
    username: 'bob',
    webUrl: '/bob',
    webPath: '/bob',
  },
];

export const mockLabels = [
  {
    __typename: 'Label',
    id: 'gid://gitlab/Label/1',
    title: 'frontend',
    description: 'Frontend work',
    color: '#ff0000',
    textColor: '#ffffff',
  },
  {
    __typename: 'Label',
    id: 'gid://gitlab/Label/2',
    title: 'bug',
    description: 'Defect',
    color: '#00ff00',
    textColor: '#000000',
  },
];

export const buildLabelsWidget = (labels = mockLabels) => ({
  __typename: 'WorkItemWidgetLabels',
  type: 'LABELS',
  labels: { nodes: labels },
});

export const buildAssigneesWidget = (assignees = mockAssignees) => ({
  __typename: 'WorkItemWidgetAssignees',
  type: 'ASSIGNEES',
  assignees: { nodes: assignees },
});

export const buildStatusWidget = (status = mockStatus) => ({
  __typename: 'WorkItemWidgetStatus',
  type: 'STATUS',
  status,
});

export const buildWorkItemNode = (id, overrides = {}) => ({
  __typename: 'WorkItem',
  id: `gid://gitlab/WorkItem/${id}`,
  iid: String(id),
  title: `Work item ${id}`,
  titleHtml: `Work item ${id}`,
  reference: `group/project#${id}`,
  state: 'OPEN',
  webPath: `/group/project/-/issues/${id}`,
  webUrl: `http://gdk.test/group/project/-/issues/${id}`,
  closedAt: null,
  createdAt: '2026-01-01T00:00:00Z',
  updatedAt: '2026-01-01T00:00:00Z',
  author: {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    avatarUrl: '/avatar.png',
    name: 'Author',
    username: 'author',
    webUrl: '/author',
    webPath: '/author',
  },
  namespace: {
    __typename: 'Group',
    id: mockGroupId,
    fullPath: 'group',
  },
  widgets: [],
  workItemType: {
    __typename: 'WorkItemType',
    id: 'gid://gitlab/WorkItems::Type/1',
    name: 'Issue',
    iconName: 'issue-type-issue',
  },
  ...overrides,
});

export const buildBoardWorkItemsResponse = (nodes = [], pageInfo = {}) => ({
  data: {
    namespace: {
      __typename: 'Group',
      id: mockGroupId,
      name: 'Test',
      workItems: {
        __typename: 'WorkItemConnection',
        pageInfo: {
          __typename: 'PageInfo',
          hasNextPage: false,
          hasPreviousPage: false,
          startCursor: null,
          endCursor: null,
          ...pageInfo,
        },
        nodes,
      },
    },
  },
});

export const buildNamespaceStatusesResponse = (statuses = []) => ({
  data: {
    namespace: {
      __typename: 'Group',
      id: mockGroupId,
      rootNamespace: {
        __typename: 'Group',
        id: mockGroupId,
        statuses: {
          __typename: 'WorkItemStatusConnection',
          nodes: statuses,
        },
      },
    },
  },
});
