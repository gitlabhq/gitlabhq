import _ from 'underscore';

export const dataStructure = () => ({
  id: '',
  key: '',
  type: '',
  projectId: '',
  branchId: '',
  name: '',
  url: '',
  path: '',
  level: 0,
  tempFile: false,
  icon: '',
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
  tree_url: '',
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

export const decorateData = (entity) => {
  const {
    id,
    projectId,
    branchId,
    type,
    url,
    name,
    icon,
    tree_url,
    path,
    renderError,
    content = '',
    tempFile = false,
    active = false,
    opened = false,
    changed = false,
    parentTreeUrl = '',
    level = 0,
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
    tree_url,
    path,
    level,
    tempFile,
    icon: `fa-${icon}`,
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

/*
  Takes the multi-dimensional tree and returns a flattened array.
  This allows for the table to recursively render the table rows but keeps the data
  structure nested to make it easier to add new files/directories.
*/
export const treeList = (state, treeId) => {
  const baseTree = state.trees[treeId];
  if (baseTree) {
    const mapTree = arr => (!arr.tree || !arr.tree.length ?
                            [] : _.map(arr.tree, a => [a, mapTree(a)]));

    return _.chain(baseTree.tree)
      .map(arr => [arr, mapTree(arr)])
      .flatten()
      .value();
  }
  return [];
};

export const getTree = state => (namespace, projectId, branch) => state.trees[`${namespace}/${projectId}/${branch}`];

export const getTreeEntry = (store, treeId, path) => {
  const fileList = treeList(store.state, treeId);
  return fileList ? fileList.find(file => file.path === path) : null;
};

export const findEntry = (tree, type, name) => tree.find(
  f => f.type === type && f.name === name,
);

export const findIndexOfFile = (state, file) => state.findIndex(f => f.path === file.path);

export const setPageTitle = (title) => {
  document.title = title;
};

export const createTemp = ({
  projectId, branchId, name, path, type, level, changed, content, base64, url,
}) => {
  const treePath = path ? `${path}/${name}` : name;

  return decorateData({
    id: new Date().getTime().toString(),
    projectId,
    branchId,
    name,
    type,
    tempFile: true,
    path: treePath,
    icon: type === 'tree' ? 'folder' : 'file-text-o',
    changed,
    content,
    parentTreeUrl: '',
    level,
    base64,
    renderError: base64,
    url,
  });
};

export const createOrMergeEntry = ({ projectId,
                                     branchId,
                                     entry,
                                     type,
                                     parentTreeUrl,
                                     level,
                                     state }) => {
  if (state.changedFiles.length) {
    const foundChangedFile = findEntry(state.changedFiles, type, entry.name);

    if (foundChangedFile) {
      return foundChangedFile;
    }
  }

  if (state.openFiles.length) {
    const foundOpenFile = findEntry(state.openFiles, type, entry.name);

    if (foundOpenFile) {
      return foundOpenFile;
    }
  }

  return decorateData({
    ...entry,
    projectId,
    branchId,
    type,
    parentTreeUrl,
    level,
  });
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
