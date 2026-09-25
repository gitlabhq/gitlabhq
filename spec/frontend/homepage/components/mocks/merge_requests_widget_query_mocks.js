const buildMergeRequest = (id, overrides = {}) => ({
  id: `gid://gitlab/MergeRequest/${id}`,
  title: `Merge request ${id}`,
  webPath: `/acme/web-app/-/merge_requests/${id}`,
  updatedAt: '2025-06-12T15:13:25Z',
  resolvedDiscussionsCount: 1,
  resolvableDiscussionsCount: 2,
  project: {
    id: `gid://gitlab/Project/${id}`,
    name: 'Web App',
    namespace: {
      id: 'gid://gitlab/Group/1',
      name: 'Acme Corp',
      __typename: 'Namespace',
    },
    __typename: 'Project',
  },
  headPipeline: {
    id: `gid://gitlab/Ci::Pipeline/${id}`,
    detailedStatus: {
      id: `status-${id}`,
      icon: 'status_success',
      text: 'Passed',
      detailsPath: `/acme/web-app/-/pipelines/${id}`,
      __typename: 'DetailedStatus',
    },
    __typename: 'Pipeline',
  },
  approved: false,
  approvalsRequired: 2,
  approvalsLeft: 1,
  approvedBy: {
    nodes: [{ id: 'gid://gitlab/User/3', __typename: 'UserCore' }],
    __typename: 'UserCoreConnection',
  },
  __typename: 'MergeRequest',
  ...overrides,
});

export const buildMergeRequests = (count, startAt = 1) =>
  Array.from({ length: count }, (_, index) => buildMergeRequest(startAt + index));

export const buildResponse = ({
  assignedCount = 2,
  assignedNodes = buildMergeRequests(2),
} = {}) => ({
  data: {
    currentUser: {
      id: 'gid://gitlab/User/1',
      assignedMergeRequests: {
        count: assignedCount,
        nodes: assignedNodes,
        __typename: 'MergeRequestConnection',
      },
      __typename: 'CurrentUser',
    },
  },
});

export const mergeRequestsResponse = buildResponse();

export const emptyMergeRequestsResponse = buildResponse({
  assignedCount: 0,
  assignedNodes: [],
});

// 9 assigned MRs: the query caps nodes at 8, so the widget shows 4 then reveals 8.
export const manyMergeRequestsResponse = buildResponse({
  assignedCount: 9,
  assignedNodes: buildMergeRequests(8),
});

export const mergeRequestWithoutMetadata = buildMergeRequest(50, {
  headPipeline: null,
  resolvableDiscussionsCount: 0,
  resolvedDiscussionsCount: 0,
  approvalsRequired: 0,
  approvalsLeft: 0,
  approvedBy: { nodes: [], __typename: 'UserCoreConnection' },
});

export { buildMergeRequest };
