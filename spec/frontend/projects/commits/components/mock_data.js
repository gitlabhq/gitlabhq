export const mockCommit = {
  __typename: 'Commit',
  id: 'gid://gitlab/Commit/8e3336548a7aa36b7cae362fbd8c694793ecc110',
  sha: '8e3336548a7aa36b7cae362fbd8c694793ecc110',
  shortId: '8e333654',
  title: 'Edit CODEOWNERS',
  titleHtml: 'Edit CODEOWNERS',
  description: 'Some commit description',
  descriptionHtml: '',
  message: 'Edit CODEOWNERS',
  webPath: '/gitlab-org/gitlab-shell/-/commit/8e3336548a7aa36b7cae362fbd8c694793ecc110',
  webUrl: '/gitlab-org/gitlab-shell/-/tree/8e3336548a7aa36b7cae362fbd8c694793ecc110',
  authoredDate: '2025-06-23T18:03:33+00:00',
  authorName: 'Administrator with very very long name',
  authorGravatar:
    'https://secure.gravatar.com/avatar/7272d4da0ca779e0ca6fdb7fdc7a17b232462e054839e1060934d03f6ded8609?s=80&d=identicon',
  author: {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/1',
    name: 'Administrator with very very long name',
    username: 'root',
    avatarUrl:
      'https://secure.gravatar.com/avatar/7272d4da0ca779e0ca6fdb7fdc7a17b232462e054839e1060934d03f6ded8609?s=80&d=identicon',
    webPath: '/root',
  },
  signature: {
    __typename: 'GpgSignature',
    gpgKeyPrimaryKeyid: '2CEAFD2671262EC2',
    verificationStatus: 'UNKNOWN_KEY',
  },
  pipelines: {
    __typename: 'PipelineConnection',
    edges: [
      {
        __typename: 'PipelineEdge',
        node: {
          __typename: 'Pipeline',
          id: 'gid://gitlab/Ci::Pipeline/621',
          detailedStatus: {
            __typename: 'DetailedStatus',
            id: 'failed-621-621',
            detailsPath: '/gitlab-org/gitlab-shell/-/pipelines/621',
            icon: 'status_failed',
            text: 'Failed',
          },
        },
      },
    ],
  },
  tag: {
    name: 'V1.2.3',
  },
};

const mockCommitSecond = {
  __typename: 'Commit',
  id: 'gid://gitlab/Commit/5f923865dde3436854e9ceb9cdb7815618d4e849',
  sha: '5f923865dde3436854e9ceb9cdb7815618d4e849',
  shortId: '5f923865',
  title: "GitLab currently doesn't support patches that involve a merge commit: add a commit here",
  titleHtml:
    "GitLab currently doesn't support patches that involve a merge commit: add a commit here",
  description: '',
  descriptionHtml: '',
  message:
    "GitLab currently doesn't support patches that involve a merge commit: add a commit here\n",
  webPath: '/gitlab-org/gitlab-test/-/commit/5f923865dde3436854e9ceb9cdb7815618d4e849',
  webUrl: '/gitlab-org/gitlab-test/-/commit/5f923865dde3436854e9ceb9cdb7815618d4e849',
  authoredDate: '2025-06-23T07:27:12+00:00',
  authorName: 'Stan Hu',
  authorGravatar:
    'https://secure.gravatar.com/avatar/0234fd3e726423a4d0b21773b3f2ae487b04bfad5d299f8a6e50fe29ca55c667?s=80&d=identicon',
  author: null,
  signature: {
    __typename: 'GpgSignature',
    gpgKeyPrimaryKeyid: '2CEAFD2671262EC2',
    verificationStatus: 'VERIFIED',
  },
  pipelines: {
    __typename: 'PipelineConnection',
    edges: [
      {
        __typename: 'PipelineEdge',
        node: {
          __typename: 'Pipeline',
          id: 'gid://gitlab/Ci::Pipeline/621',
          detailedStatus: {
            __typename: 'DetailedStatus',
            id: 'success-621-621',
            detailsPath: '/gitlab-org/gitlab-shell/-/pipelines/621',
            icon: 'status_success',
            text: 'Passed',
          },
        },
      },
    ],
  },
  tag: {
    name: 'very long tag to test out layout is doing okay',
  },
};

const mockCommitThird = {
  __typename: 'Commit',
  id: 'gid://gitlab/Commit/abc123def456',
  sha: 'abc123def456',
  shortId: 'abc123de',
  title: 'Another commit on a different day',
  titleHtml: 'Another commit on a different day',
  description: '',
  descriptionHtml: '',
  message: 'Another commit on a different day\n',
  webPath: '/gitlab-org/gitlab-test/-/commit/abc123def456',
  webUrl: '/gitlab-org/gitlab-test/-/commit/abc123def456',
  authoredDate: '2025-06-21T18:03:33+00:00',
  authorName: 'Alfonzo Dickinson',
  authorGravatar:
    'https://secure.gravatar.com/avatar/95ed2ed013f50a00587f6715b6f1e0d0ea50a6bb77bfd6e00556254f3efe25cd?s=80&d=identicon&width=96',
  author: {
    __typename: 'UserCore',
    id: 'gid://gitlab/User/8',
    name: 'Alfonzo Dickinson',
    username: 'andera_welch',
    avatarUrl:
      'https://secure.gravatar.com/avatar/95ed2ed013f50a00587f6715b6f1e0d0ea50a6bb77bfd6e00556254f3efe25cd?s=80&d=identicon&width=96',
    webPath: '/andera_welch',
  },
  signature: null,
  pipelines: {
    __typename: 'PipelineConnection',
    edges: [],
  },
};

// Flat array of commits as returned by GraphQL
export const mockCommitsNodes = [mockCommit, mockCommitSecond, mockCommitThird];

const createMockResponse = (nodes, pageInfo = {}) => ({
  data: {
    project: {
      __typename: 'Project',
      id: 'gid://gitlab/Project/1',
      repository: {
        __typename: 'Repository',
        commits: {
          __typename: 'CommitConnection',
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
  },
});

export const mockCommitsQueryResponse = createMockResponse(mockCommitsNodes);

export const mockEmptyCommitsQueryResponse = createMockResponse([]);

export const mockCommitsQueryResponseWithNextPage = createMockResponse(mockCommitsNodes, {
  hasNextPage: true,
  endCursor: 'end-cursor-1',
});

export const mockCommitsQueryResponseSecondPage = createMockResponse(mockCommitsNodes, {
  hasNextPage: true,
  endCursor: 'end-cursor-2',
});

export const mockCommitDescriptionQueryResponse = (descriptionHtml = 'Commit description') => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/1',
      repository: {
        commit: {
          id: mockCommit.id,
          descriptionHtml,
        },
      },
    },
  },
});
