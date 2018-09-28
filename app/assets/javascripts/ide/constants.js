// Fuzzy file finder
export const MAX_FILE_FINDER_RESULTS = 40;
export const FILE_FINDER_ROW_HEIGHT = 55;
export const FILE_FINDER_EMPTY_ROW_HEIGHT = 33;

export const MAX_WINDOW_HEIGHT_COMPACT = 750;

// Commit message textarea
export const MAX_TITLE_LENGTH = 50;
export const MAX_BODY_LENGTH = 72;

export const activityBarViews = {
  edit: 'ide-tree',
  commit: 'commit-section',
  review: 'ide-review',
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
};

export const rightSidebarViews = {
  pipelines: 'pipelines-list',
  jobsDetail: 'jobs-detail',
  mergeRequestInfo: 'merge-request-info',
  clientSidePreview: 'clientside',
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
};

export const packageJsonPath = 'package.json';
