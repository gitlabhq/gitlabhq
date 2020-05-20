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
  richData: '<h1>Rich</h1>',
};

export const SimpleBlobContentMock = {
  plainData: 'Plain',
};

export default {};
