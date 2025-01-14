export function createMockMergeRequest(mergeRequest = {}) {
  return {
    id: 1,
    reference: '!1',
    title: 'Title',
    webUrl: '/',
    draft: false,
    state: 'opened',
    author: {
      id: 1,
      avatarUrl: '/',
      name: 'name',
      username: 'username',
      webUrl: '/',
      webPath: '/',
    },
    milestone: null,
    diffStatsSummary: {
      fileCount: 1,
      additions: 100,
      deletions: 50,
    },
    assignees: {
      nodes: [],
    },
    reviewers: {
      nodes: [],
    },
    headPipeline: null,
    userNotesCount: 0,
    resolvedDiscussionsCount: 0,
    resolvableDiscussionsCount: 0,
    commitCount: 0,
    sourceBranchExists: true,
    targetBranchExists: true,
    conflicts: false,
    mergedAt: '',
    createdAt: '',
    updatedAt: '',
    approved: false,
    approvalsRequired: 0,
    approvalsLeft: null,
    approvedBy: {
      nodes: [],
    },
    __typename: 'MergeRequest',
    ...mergeRequest,
  };
}
