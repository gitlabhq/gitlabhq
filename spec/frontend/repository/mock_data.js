export const simpleViewerMock = {
  __typename: 'RepositoryBlob',
  id: '1',
  name: 'some_file.js',
  size: 123,
  rawSize: 123,
  rawTextBlob: 'raw content',
  fileType: 'text',
  language: 'javascript',
  path: 'some_file.js',
  webPath: 'some_file.js',
  blamePath: 'blame/file.js',
  editBlobPath: 'some_file.js/edit',
  gitpodBlobUrl: 'https://gitpod.io#path/to/blob.js',
  ideEditPath: 'some_file.js/ide/edit',
  forkAndEditPath: 'some_file.js/fork/edit',
  ideForkAndEditPath: 'some_file.js/fork/ide',
  forkAndViewPath: 'some_file.js/fork/view',
  codeNavigationPath: '',
  projectBlobPathRoot: '',
  environmentFormattedExternalUrl: '',
  environmentExternalUrlForRouteMap: '',
  canModifyBlob: true,
  canCurrentUserPushToBranch: true,
  archived: false,
  storedExternally: false,
  externalStorageUrl: '',
  externalStorage: 'lfs',
  rawPath: 'some_file.js',
  replacePath: 'some_file.js/replace',
  pipelineEditorPath: 'path/to/pipeline/editor',
  simpleViewer: {
    fileType: 'text',
    tooLarge: false,
    type: 'simple',
    renderError: null,
  },
  richViewer: null,
};

export const richViewerMock = {
  ...simpleViewerMock,
  richViewer: {
    fileType: 'markup',
    tooLarge: false,
    type: 'rich',
    renderError: null,
  },
};

export const userPermissionsMock = {
  pushCode: true,
  forkProject: true,
  downloadCode: true,
  createMergeRequestIn: true,
};

export const projectMock = {
  __typename: 'Project',
  id: '1234',
  userPermissions: userPermissionsMock,
  pathLocks: {
    nodes: [
      {
        id: 'test',
        path: 'locked_file.js',
        user: { id: '123', username: 'root' },
      },
    ],
  },
  repository: {
    empty: false,
  },
};

export const propsMock = { path: 'some_file.js', projectPath: 'some/path' };

export const refMock = 'default-ref';
export const refWithSpecialCharMock = 'feat/selected-#-ref-#';
export const encodedRefWithSpecialCharMock = 'feat/selected-%23-ref-%23';

export const blobControlsDataMock = {
  id: '1234',
  repository: {
    blobs: {
      nodes: [
        {
          id: '5678',
          findFilePath: 'find/file.js',
          blamePath: 'blame/file.js',
          historyPath: 'history/file.js',
          permalinkPath: 'permalink/file.js',
          storedExternally: false,
          externalStorage: '',
        },
      ],
    },
  },
};

export const graphQLErrors = [
  {
    message: '14:failed to connect to all addresses.',
    locations: [{ line: 16, column: 7 }],
    path: ['project', 'repository', 'paginatedTree'],
    extensions: { code: 'unavailable', gitaly_code: 14, service: 'git' },
  },
];

export const propsForkInfo = {
  projectPath: 'nataliia/myGitLab',
  selectedBranch: 'main',
  sourceName: 'gitLab',
  sourcePath: 'gitlab-org/gitlab',
  canSyncBranch: true,
  aheadComparePath: '/nataliia/myGitLab/-/compare/main...ref?from_project_id=1',
  behindComparePath: 'gitlab-org/gitlab/-/compare/ref...main?from_project_id=2',
  createMrPath: 'path/to/new/mr',
};

export const propsConflictsModal = {
  sourceDefaultBranch: 'branch-name',
  sourceName: 'source-name',
  sourcePath: 'path/to/project',
  selectedBranch: 'my-branch',
};

export const paginatedTreeResponseFactory = ({
  numberOfBlobs = 3,
  numberOfTrees = 3,
  hasNextPage = false,
  blobHasReadme = false,
} = {}) => ({
  data: {
    project: {
      id: 'gid://gitlab/Project/278964',
      __typename: 'Project',
      repository: {
        __typename: 'Repository',
        paginatedTree: {
          __typename: 'TreeConnection',
          pageInfo: {
            __typename: 'PageInfo',
            endCursor: hasNextPage ? 'aaa' : '',
            startCursor: '',
            hasNextPage,
          },
          nodes: [
            {
              __typename: 'Tree',
              trees: {
                __typename: 'TreeEntryConnection',
                nodes: new Array(numberOfTrees).fill({
                  __typename: 'TreeEntry',
                  id:
                    'gid://gitlab/Gitlab::Graphql::Representation::TreeEntry/dc36320ac91aca2f890a31458c9e9920159e68a3',
                  sha: 'dc36320ac91aca2f890a31458c9e9920159e68ae',
                  name: 'gitlab-resize-image',
                  flatPath: 'workhorse/cmd/gitlab-resize-image',
                  type: 'tree',
                  webPath: '/gitlab-org/gitlab/-/tree/master/workhorse/cmd/gitlab-resize-image',
                }),
              },
              submodules: {
                __typename: 'SubmoduleConnection',
                nodes: [],
              },
              blobs: {
                __typename: 'BlobConnection',
                nodes: new Array(numberOfBlobs).fill({
                  __typename: 'Blob',
                  id:
                    'gid://gitlab/Gitlab::Graphql::Representation::TreeEntry/99712dbc6b26ff92c15bf93449ea09df38adfb10',
                  sha: '99712dbc6b26ff92c15bf93449ea09df38adfb1b',
                  name: blobHasReadme ? 'README.md' : 'fakeBlob',
                  flatPath: blobHasReadme ? 'README.md' : 'fakeBlob',
                  type: 'blob',
                  mode: '100644',
                  webPath: '/gitlab-org/gitlab-build-images/-/blob/master/README.md',
                  lfsOid: null,
                }),
              },
            },
          ],
        },
      },
    },
  },
});

export const axiosMockResponse = { html: 'text', binary: true };
