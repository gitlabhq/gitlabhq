export const mockGroupId = 'gid://gitlab/Group/1';

export const buildStatus = (id, name = `Status ${id}`, category = 'to_do') => ({
  __typename: 'WorkItemStatusCustom',
  id: `gid://gitlab/WorkItems::Statuses::Custom::Status/${id}`,
  name,
  iconName: 'status-waiting',
  color: '#737278',
  category,
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

export const mockMilestone = {
  __typename: 'Milestone',
  id: 'gid://gitlab/Milestone/1',
  title: 'v1.0',
  startDate: '2026-01-01',
  dueDate: '2026-03-01',
  webPath: '/group/project/-/milestones/1',
};

export const buildMilestoneWidget = (milestone = mockMilestone) => ({
  __typename: 'WorkItemWidgetMilestone',
  type: 'MILESTONE',
  milestone,
});

export const buildStartAndDueDateWidget = ({ dueDate = '2026-03-01', startDate = null } = {}) => ({
  __typename: 'WorkItemWidgetStartAndDueDate',
  type: 'START_AND_DUE_DATE',
  dueDate,
  startDate,
});

export const buildWeightWidget = (weight = 3) => ({
  __typename: 'WorkItemWidgetWeight',
  type: 'WEIGHT',
  weight,
});

export const mockIteration = {
  __typename: 'Iteration',
  id: 'gid://gitlab/Iteration/1',
  title: 'Sprint 1',
  startDate: '2026-01-01',
  dueDate: '2026-01-14',
  webUrl: '/group/-/cadences/1/iterations/1',
  iterationCadence: {
    __typename: 'IterationCadence',
    id: 'gid://gitlab/Iterations::Cadence/1',
    title: 'Cadence 1',
  },
};

export const buildIterationWidget = (iteration = mockIteration) => ({
  __typename: 'WorkItemWidgetIteration',
  type: 'ITERATION',
  iteration,
});

export const buildHealthStatusWidget = (healthStatus = 'onTrack') => ({
  __typename: 'WorkItemWidgetHealthStatus',
  type: 'HEALTH_STATUS',
  healthStatus,
});

export const buildLinkedItemsWidget = ({ blockingCount = 0, blockedByCount = 0 } = {}) => ({
  __typename: 'WorkItemWidgetLinkedItems',
  type: 'LINKED_ITEMS',
  blockingCount,
  blockedByCount,
});

export const mockParent = {
  __typename: 'WorkItem',
  id: 'gid://gitlab/WorkItem/100',
  iid: '100',
  title: 'Parent epic',
  webUrl: 'http://gdk.test/group/-/epics/100',
  confidential: false,
  namespace: {
    __typename: 'Group',
    id: mockGroupId,
    fullPath: 'group',
  },
  workItemType: {
    __typename: 'WorkItemType',
    id: 'gid://gitlab/WorkItems::Type/2',
    name: 'Epic',
    iconName: 'issue-type-epic',
  },
};

export const buildHierarchyWidget = (parent = mockParent) => ({
  __typename: 'WorkItemWidgetHierarchy',
  type: 'HIERARCHY',
  parent,
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

export const buildBoardWorkItemsCountResponse = (count = 0) => ({
  data: {
    namespace: {
      __typename: 'Group',
      id: mockGroupId,
      name: 'Test',
      workItems: {
        __typename: 'WorkItemConnection',
        count,
      },
    },
  },
});

export const buildWorkItemTypesResponse = (types = []) => ({
  data: {
    namespace: {
      __typename: 'Namespace',
      id: mockGroupId,
      webUrl: '/group',
      userPermissions: {
        __typename: 'NamespacePermissions',
        setNewWorkItemMetadata: true,
      },
      workItemTypes: {
        __typename: 'WorkItemTypeConnection',
        nodes: types,
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
