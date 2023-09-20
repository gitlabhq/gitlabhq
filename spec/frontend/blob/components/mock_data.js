import { SIMPLE_BLOB_VIEWER, RICH_BLOB_VIEWER } from '~/blob/components/constants';

export const SimpleViewerMock = {
  collapsed: false,
  loadingPartialName: 'loading',
  renderError: null,
  tooLarge: false,
  type: SIMPLE_BLOB_VIEWER,
  fileType: 'text',
};

export const RichViewerMock = {
  collapsed: false,
  loadingPartialName: 'loading',
  renderError: null,
  tooLarge: false,
  type: RICH_BLOB_VIEWER,
  fileType: 'markdown',
};

export const Blob = {
  binary: false,
  name: 'dummy.md',
  path: 'foo/bar/dummy.md',
  rawPath: 'https://testing.com/flightjs/flight/snippets/51/raw',
  size: 75,
  simpleViewer: {
    ...SimpleViewerMock,
  },
  richViewer: {
    ...RichViewerMock,
  },
  ideEditPath: 'ide/edit',
  editBlobPath: 'edit/blob',
  gitpodBlobUrl: 'gitpod/blob/url',
  pipelineEditorPath: 'pipeline/editor/path',
};

export const BinaryBlob = {
  binary: true,
  name: 'dummy.png',
  path: 'foo/bar/dummy.png',
  rawPath: '/flightjs/flight/snippets/51/raw',
  size: 75,
  simpleViewer: {
    ...SimpleViewerMock,
  },
  richViewer: {
    ...RichViewerMock,
  },
};

export const RichBlobContentMock = {
  __typename: 'Blob',
  path: 'foo.md',
  richData: '<h1>Rich</h1>',
};

export const SimpleBlobContentMock = {
  __typename: 'Blob',
  path: 'foo.js',
  plainData: 'Plain',
};

export const mockEnvironmentName = 'my.testing.environment';
export const mockEnvironmentPath = 'https://my.testing.environment';

export const userInfoMock = {
  currentUser: {
    id: '123',
    gitpodEnabled: true,
    preferencesGitpodPath: '/-/profile/preferences#user_gitpod_enabled',
    profileEnableGitpodPath: '/-/profile?user%5Bgitpod_enabled%5D=true',
  },
};

export const applicationInfoMock = { gitpodEnabled: true };
