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
  staged: false,
  lastCommitPath: '',
  lastCommitSha: '',
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
  viewMode: 'editor',
  previewMode: null,
  size: 0,
  parentPath: null,
  lastOpenedAt: 0,
  mrChange: null,
  deleted: false,
  prevPath: '',
  movedPath: '',
  moved: false,
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
    previewMode,
    file_lock,
    html,
    parentPath = '',
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
    previewMode,
    file_lock,
    html,
    parentPath,
  };
};

export const findEntry = (tree, type, name, prop = 'name') =>
  tree.find(f => f.type === type && f[prop] === name);

export const findIndexOfFile = (state, file) => state.findIndex(f => f.path === file.path);

export const setPageTitle = title => {
  document.title = title;
};

export const commitActionForFile = file => {
  if (file.prevPath) {
    return 'move';
  } else if (file.deleted) {
    return 'delete';
  } else if (file.tempFile) {
    return 'create';
  }

  return 'update';
};

export const getCommitFiles = (stagedFiles, deleteTree = false) =>
  stagedFiles.reduce((acc, file) => {
    if (file.moved) return acc;

    if ((file.deleted || deleteTree || file.prevPath) && file.type === 'tree') {
      return acc.concat(getCommitFiles(file.tree, true));
    }

    return acc.concat({
      ...file,
      deleted: deleteTree || file.deleted,
    });
  }, []);

export const createCommitPayload = ({ branch, getters, newBranch, state, rootState }) => ({
  branch,
  commit_message: state.commitMessage || getters.preBuiltCommitMessage,
  actions: getCommitFiles(rootState.stagedFiles).map(f => ({
    action: commitActionForFile(f),
    file_path: f.path,
    previous_path: f.prevPath === '' ? undefined : f.prevPath,
    content: f.content,
    encoding: f.base64 ? 'base64' : 'text',
    last_commit_id: newBranch || f.deleted || f.prevPath ? undefined : f.lastCommitSha,
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
  if (a.name < b.name) return -1;
  if (a.name > b.name) return 1;
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

export const filePathMatches = (f, path) =>
  f.path.replace(new RegExp(`${f.name}$`), '').indexOf(`${path}/`) === 0;

export const getChangesCountForFiles = (files, path) =>
  files.filter(f => filePathMatches(f, path)).length;
