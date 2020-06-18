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
  edit: { name: 'ide-tree', keepAlive: false },
  review: { name: 'ide-review', keepAlive: false },
  commit: { name: 'repo-commit-section', keepAlive: false },
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
