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
  canModifyBlobWithWebIde: true,
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
  __typename: 'ProjectPermissions',
};

export const getProjectMockWithOverrides = ({ userPermissionsOverride = {} } = {}) => ({
  __typename: 'Project',
  id: 'gid://gitlab/Project/7',
  userPermissions: { ...userPermissionsMock, ...userPermissionsOverride },
  repository: {
    empty: false,
  },
});

export const projectMock = getProjectMockWithOverrides();

export const propsMock = { path: 'some_file.js', projectPath: 'some/path' };

export const refMock = 'default-ref';
export const refWithSpecialCharMock = 'feat/selected-#-ref-#';
export const encodedRefWithSpecialCharMock = 'feat/selected-%23-ref-%23';

export const blobControlsDataMock = {
  __typename: 'Project',
  id: '1234',
  userPermissions: userPermissionsMock,
  repository: {
    __typename: 'Repository',
    empty: false,
    blobs: {
      __typename: 'RepositoryBlobConnection',
      nodes: [
        {
          __typename: 'RepositoryBlob',
          id: '5678',
          name: 'file.js',
          blamePath: 'blame/file.js',
          permalinkPath: 'permalink/file.js',
          path: 'some/file.js',
          storedExternally: false,
          externalStorage: 'https://external-storage',
          environmentFormattedExternalUrl: 'my.testing.environment',
          environmentExternalUrlForRouteMap: 'https://my.testing.environment',
          rawPath: 'https://testing.com/flightjs/flight/snippets/51/raw',
          rawTextBlob: 'Example raw text content',
          archived: false,
          replacePath: 'some/replace/file.js',
          webPath: 'some/file.js',
          canCurrentUserPushToBranch: true,
          canModifyBlob: true,
          canModifyBlobWithWebIde: true,
          forkAndViewPath: 'fork/view/path',
          editBlobPath: 'https://edit/blob/path/file.js',
          ideEditPath: 'https://ide/blob/path/file.js',
          pipelineEditorPath: 'pipeline/editor/path/file.yml',
          gitpodBlobUrl: 'gitpod/blob/url/file.js',
          simpleViewer: {
            __typename: 'BlobViewer',
            collapsed: false,
            loadingPartialName: 'loading',
            renderError: null,
            tooLarge: false,
            type: 'simple',
            fileType: 'rich',
          },
          richViewer: {
            __typename: 'BlobViewer',
            collapsed: false,
            loadingPartialName: 'loading',
            renderError: 'too big file',
            tooLarge: false,
            type: 'rich',
            fileType: 'rich',
          },
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
                  id: 'gid://gitlab/Gitlab::Graphql::Representation::TreeEntry/dc36320ac91aca2f890a31458c9e9920159e68a3',
                  sha: 'dc36320ac91aca2f890a31458c9e9920159e68ae',
                  name: 'gitlab-resize-image',
                  flatPath: 'workhorse/cmd/gitlab-resize-image',
                  path: 'workhorse/cmd/gitlab-resize-image',
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
                  id: 'gid://gitlab/Gitlab::Graphql::Representation::TreeEntry/99712dbc6b26ff92c15bf93449ea09df38adfb10',
                  sha: '99712dbc6b26ff92c15bf93449ea09df38adfb1b',
                  name: blobHasReadme ? 'README.md' : 'fakeBlob',
                  flatPath: blobHasReadme ? 'README.md' : 'fakeBlob',
                  path: 'README.md',
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

export const headerAppInjected = {
  canCollaborate: true,
  canEditTree: true,
  canPushCode: true,
  canPushToBranch: true,
  originalBranch: 'main',
  selectedBranch: 'feature/new-ui',
  newBranchPath: '/project/new-branch',
  newTagPath: '/project/new-tag',
  newBlobPath: '/project/new-file',
  forkNewBlobPath: '/project/fork/new-file',
  forkNewDirectoryPath: '/project/fork/new-directory',
  forkUploadBlobPath: '/project/fork/upload',
  uploadPath: '/project/upload',
  newDirPath: '/project/new-directory',
  projectRootPath: '/project/root/path',
  comparePath: undefined,
  isReadmeView: false,
  isFork: false,
  needsToFork: true,
  isGitpodEnabledForUser: false,
  isBlob: true,
  showEditButton: true,
  showWebIdeButton: true,
  isGitpodEnabledForInstance: false,
  showPipelineEditorUrl: true,
  webIdeUrl: 'https://gitlab.com/project/-/ide/',
  editUrl: 'https://gitlab.com/project/-/edit/main/',
  pipelineEditorUrl: 'https://gitlab.com/project/-/ci/editor',
  gitpodUrl: 'https://gitpod.io/#https://gitlab.com/project',
  userPreferencesGitpodPath: '/profile/preferences#gitpod',
  userProfileEnableGitpodPath: '/profile/preferences?enable_gitpod=true',
  httpUrl: 'https://gitlab.com/example-group/example-project.git',
  xcodeUrl: 'xcode://clone?repo=https://gitlab.com/example-group/example-project.git',
  sshUrl: 'git@gitlab.com:example-group/example-project.git',
  kerberosUrl: '',
  downloadLinks: [
    'https://gitlab.com/example-group/example-project/-/archive/main/example-project-main.zip',
    'https://gitlab.com/example-group/example-project/-/archive/main/example-project-main.tar.gz',
    'https://gitlab.com/example-group/example-project/-/archive/main/example-project-main.tar.bz2',
    'https://gitlab.com/example-group/example-project/-/releases',
  ],
  downloadArtifacts: [
    'https://gitlab.com/example-group/example-project/-/jobs/artifacts/main/download?job=build',
  ],
  isBinary: false,
  rootRef: 'main',
};

export const FILE_SIZE_3MB = 3000000;

export const currentUserDataMock = {
  __typename: 'User',
  id: '1234',
  gitpodEnabled: true,
  preferencesGitpodPath: 'preferences/gitpod/path',
  profileEnableGitpodPath: 'profile/enable/gitpod/path',
};

export const applicationInfoMock = { gitpodEnabled: true };

export const mockPipelineStatusUpdatedResponse = {
  data: {
    ciPipelineStatusUpdated: {
      id: 'gid://gitlab/Ci::Pipeline/1257',
      retryable: false,
      cancelable: false,
      __typename: 'Pipeline',
      detailedStatus: {
        detailsPath: '/root/simple-ci-project/-/pipelines/1257',
        icon: 'status_success',
        id: 'success-1255-1255',
        label: 'passed',
        text: 'Passed',
        __typename: 'DetailedStatus',
      },
    },
  },
};

const defaultPipelineEdges = [
  {
    __typename: 'PipelineEdge',
    node: {
      __typename: 'Pipeline',
      id: 'gid://gitlab/Ci::Pipeline/167',
      detailedStatus: {
        __typename: 'DetailedStatus',
        id: 'id',
        detailsPath: 'https://test.com/pipeline',
        icon: 'status_running',
        text: 'failed',
      },
    },
  },
];

export const createCommitData = ({ pipelineEdges = defaultPipelineEdges, signature = null }) => {
  return {
    data: {
      project: {
        __typename: 'Project',
        id: 'gid://gitlab/Project/6',
        repository: {
          __typename: 'Repository',
          lastCommit: {
            __typename: 'Commit',
            id: 'gid://gitlab/CommitPresenter/123456789',
            sha: '123456789',
            title: 'Commit title',
            titleHtml: 'Commit title',
            descriptionHtml: '',
            message: '',
            webPath: '/commit/123',
            committerName: 'Test Committer',
            committerEmail: 'testcommitter@example.com',
            committedDate: '2019-02-02',
            authoredDate: '2019-01-01',
            authorName: 'Test',
            authorEmail: 'testauthor@example.com',
            authorGravatar: 'https://test.com',
            author: {
              __typename: 'UserCore',
              id: 'gid://gitlab/User/1',
              name: 'Test',
              avatarUrl: 'https://test.com',
              webPath: '/test',
            },
            signature,
            pipelines: {
              __typename: 'PipelineConnection',
              edges: pipelineEdges,
            },
          },
        },
      },
    },
  };
};
