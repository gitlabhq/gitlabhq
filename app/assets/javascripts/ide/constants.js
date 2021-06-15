export const MAX_WINDOW_HEIGHT_COMPACT = 750;

// Commit message textarea
export const MAX_TITLE_LENGTH = 50;
export const MAX_BODY_LENGTH = 72;

export const SIDEBAR_INIT_WIDTH = 340;
export const SIDEBAR_MIN_WIDTH = 340;
export const SIDEBAR_NAV_WIDTH = 60;

// File view modes
export const FILE_VIEW_MODE_EDITOR = 'editor';
export const FILE_VIEW_MODE_PREVIEW = 'preview';

export const PERMISSION_CREATE_MR = 'createMergeRequestIn';
export const PERMISSION_READ_MR = 'readMergeRequest';
export const PERMISSION_PUSH_CODE = 'pushCode';
export const PUSH_RULE_REJECT_UNSIGNED_COMMITS = 'rejectUnsignedCommits';

// The default permission object to use when the project data isn't available yet.
// This helps us encapsulate checks like `canPushCode` without requiring an
// additional check like `currentProject && canPushCode`.
export const DEFAULT_PERMISSIONS = {
  [PERMISSION_PUSH_CODE]: true,
};

export const viewerTypes = {
  mr: 'mrdiff',
  edit: 'editor',
  diff: 'diff',
};

export const diffModes = {
  replaced: 'replaced',
  new: 'new',
  deleted: 'deleted',
  renamed: 'renamed',
  mode_changed: 'mode_changed',
};

export const diffViewerModes = Object.freeze({
  not_diffable: 'not_diffable',
  no_preview: 'no_preview',
  added: 'added',
  deleted: 'deleted',
  renamed: 'renamed',
  mode_changed: 'mode_changed',
  text: 'text',
  image: 'image',
});

export const diffViewerErrors = Object.freeze({
  too_large: 'too_large',
  stored_externally: 'server_side_but_stored_externally',
});

export const leftSidebarViews = {
  edit: { name: 'ide-tree' },
  review: { name: 'ide-review' },
  commit: { name: 'repo-commit-section' },
};

export const rightSidebarViews = {
  pipelines: { name: 'pipelines-list', keepAlive: true },
  jobsDetail: { name: 'jobs-detail', keepAlive: false },
  mergeRequestInfo: { name: 'merge-request-info', keepAlive: true },
  clientSidePreview: { name: 'clientside', keepAlive: false },
  terminal: { name: 'terminal', keepAlive: true },
};

export const stageKeys = {
  unstaged: 'unstaged',
  staged: 'staged',
};

export const commitItemIconMap = {
  addition: {
    icon: 'file-addition',
    class: 'ide-file-addition',
  },
  modified: {
    icon: 'file-modified',
    class: 'ide-file-modified',
  },
  deleted: {
    icon: 'file-deletion',
    class: 'ide-file-deletion',
  },
};

export const modalTypes = {
  rename: 'rename',
  tree: 'tree',
  blob: 'blob',
};

export const commitActionTypes = {
  move: 'move',
  delete: 'delete',
  create: 'create',
  update: 'update',
};

export const packageJsonPath = 'package.json';

export const SIDE_LEFT = 'left';
export const SIDE_RIGHT = 'right';

// Live Preview feature
export const LIVE_PREVIEW_DEBOUNCE = 2000;

// This is the maximum number of files to auto open when opening the Web IDE
// from a merge request
export const MAX_MR_FILES_AUTO_OPEN = 10;

export const DEFAULT_BRANCH = 'main';
