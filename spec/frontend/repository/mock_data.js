export const simpleViewerMock = {
  id: '1',
  name: 'some_file.js',
  size: 123,
  rawSize: 123,
  rawTextBlob: 'raw content',
  fileType: 'text',
  path: 'some_file.js',
  webPath: 'some_file.js',
  editBlobPath: 'some_file.js/edit',
  ideEditPath: 'some_file.js/ide/edit',
  forkAndEditPath: 'some_file.js/fork/edit',
  ideForkAndEditPath: 'some_file.js/fork/ide',
  canModifyBlob: true,
  canCurrentUserPushToBranch: true,
  archived: false,
  storedExternally: false,
  externalStorage: 'lfs',
  rawPath: 'some_file.js',
  replacePath: 'some_file.js/replace',
  pipelineEditorPath: '',
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
