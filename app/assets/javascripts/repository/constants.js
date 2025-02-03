import { __ } from '~/locale';

export const GITALY_UNAVAILABLE_CODE = 'unavailable';
export const TREE_PAGE_LIMIT = 1000; // the maximum amount of items per page
export const TREE_PAGE_SIZE = 100; // the amount of items to be fetched per (batch) request

export const COMMIT_BATCH_SIZE = 25; // we request commit data in batches of 25

export const COMMIT_MESSAGE_SUBJECT_MAX_LENGTH = 52;
export const COMMIT_MESSAGE_BODY_MAX_LENGTH = 72;

export const I18N_COMMIT_DATA_FETCH_ERROR = __('An error occurred while fetching commit data.');

export const PDF_MAX_FILE_SIZE = 10000000; // 10 MB
export const PDF_MAX_PAGE_LIMIT = 50;

export const ROW_APPEAR_DELAY = 150;

export const DEFAULT_BLOB_INFO = {
  userPermissions: {
    pushCode: false,
    downloadCode: false,
    createMergeRequestIn: false,
    forkProject: false,
  },
  pathLocks: {
    nodes: [],
  },
  repository: {
    empty: true,
    blobs: {
      nodes: [
        {
          name: '',
          size: '',
          rawTextBlob: '',
          type: '',
          fileType: '',
          tooLarge: false,
          path: '',
          editBlobPath: '',
          gitpodBlobUrl: '',
          ideEditPath: '',
          forkAndEditPath: '',
          ideForkAndEditPath: '',
          codeNavigationPath: '',
          projectBlobPathRoot: '',
          forkAndViewPath: '',
          storedExternally: false,
          externalStorage: '',
          environmentFormattedExternalUrl: '',
          environmentExternalUrlForRouteMap: '',
          canModifyBlob: false,
          canCurrentUserPushToBranch: false,
          archived: false,
          rawPath: '',
          externalStorageUrl: '',
          replacePath: '',
          pipelineEditorPath: '',
          deletePath: '',
          simpleViewer: {},
          richViewer: null,
          webPath: '',
        },
      ],
    },
  },
};

export const JSON_LANGUAGE = 'json';
export const OPENAPI_FILE_TYPE = 'openapi';
export const TEXT_FILE_TYPE = 'text';
export const EMPTY_FILE = 'empty';

export const LFS_STORAGE = 'lfs';

/**
 * We have some features (like linking to external dependencies) that our frontend highlighter
 * do not yet support.
 * These are file types that we want the legacy (backend) syntax highlighter to highlight.
 */
export const LEGACY_FILE_TYPES = [
  'podfile',
  'podspec',
  'cartfile',
  'requirements_txt',
  'cargo_toml',
  'go_mod',
];

export const i18n = {
  generalError: __('An error occurred while fetching folder content.'),
  gitalyError: __('Error: Gitaly is unavailable. Contact your administrator.'),
};

export const FIVE_MINUTES_IN_MS = 1000 * 60 * 5;

export const POLLING_INTERVAL_DEFAULT = 2500;
export const POLLING_INTERVAL_BACKOFF = 2;

export const CONFLICTS_MODAL_ID = 'fork-sync-conflicts-modal';

export const FORK_UPDATED_EVENT = 'fork:updated';
