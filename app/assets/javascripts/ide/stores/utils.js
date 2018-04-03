export const dataStructure = () => ({
  id: '',
  // Key will contain a mixture of ID and path
  // it can also contain a prefix `pending-` for files opened in review mode
  key: '',
  type: '',
  projectId: '',
  branchId: '',
  name: '',
  url: '',
  path: '',
  tempFile: false,
  tree: [],
  loading: false,
  opened: false,
  active: false,
  changed: false,
  lastCommitPath: '',
  lastCommit: {
    id: '',
    url: '',
    message: '',
    updatedAt: '',
    author: '',
  },
  blamePath: '',
  commitsPath: '',
  permalink: '',
  rawPath: '',
  binary: false,
  html: '',
  raw: '',
  content: '',
  parentTreeUrl: '',
  renderError: false,
  base64: false,
  editorRow: 1,
  editorColumn: 1,
  fileLanguage: '',
  eol: '',
});

export const decorateData = entity => {
  const {
    id,
    projectId,
    branchId,
    type,
    url,
    name,
    path,
    renderError,
    content = '',
    tempFile = false,
    active = false,
    opened = false,
    changed = false,
    parentTreeUrl = '',
    base64 = false,

    file_lock,
  } = entity;

  return {
    ...dataStructure(),
    id,
    projectId,
    branchId,
    key: `${name}-${type}-${id}`,
    type,
    name,
    url,
    path,
    tempFile,
    opened,
    active,
    parentTreeUrl,
    changed,
    renderError,
    content,
    base64,

    file_lock,
  };
};

export const findEntry = (tree, type, name, prop = 'name') =>
  tree.find(f => f.type === type && f[prop] === name);

export const findIndexOfFile = (state, file) => state.findIndex(f => f.path === file.path);

export const setPageTitle = title => {
  document.title = title;
};

export const createCommitPayload = (branch, newBranch, state, rootState) => ({
  branch,
  commit_message: state.commitMessage,
  actions: rootState.changedFiles.map(f => ({
    action: f.tempFile ? 'create' : 'update',
    file_path: f.path,
    content: f.content,
    encoding: f.base64 ? 'base64' : 'text',
  })),
  start_branch: newBranch ? rootState.currentBranchId : undefined,
});

export const createNewMergeRequestUrl = (projectUrl, source, target) =>
  `${projectUrl}/merge_requests/new?merge_request[source_branch]=${source}&merge_request[target_branch]=${target}`;

const sortTreesByTypeAndName = (a, b) => {
  if (a.type === 'tree' && b.type === 'blob') {
    return -1;
  } else if (a.type === 'blob' && b.type === 'tree') {
    return 1;
  }
  if (a.name.toLowerCase() < b.name.toLowerCase()) return -1;
  if (a.name.toLowerCase() > b.name.toLowerCase()) return 1;
  return 0;
};

export const sortTree = sortedTree =>
  sortedTree
    .map(entity =>
      Object.assign(entity, {
        tree: entity.tree.length ? sortTree(entity.tree) : [],
      }),
    )
    .sort(sortTreesByTypeAndName);
