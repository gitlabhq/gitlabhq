import { commitActionTypes } from '../constants';

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
  replaces: false,
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
    binary = false,
    rawPath = '',
    previewMode,
    file_lock,
    html,
    parentPath = '',
  } = entity;

  return Object.assign(dataStructure(), {
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
    binary,
    rawPath,
    previewMode,
    file_lock,
    html,
    parentPath,
  });
};

export const findEntry = (tree, type, name, prop = 'name') =>
  tree.find(f => f.type === type && f[prop] === name);

export const findIndexOfFile = (state, file) => state.findIndex(f => f.path === file.path);

export const setPageTitle = title => {
  document.title = title;
};

export const commitActionForFile = file => {
  if (file.prevPath) {
    return commitActionTypes.move;
  } else if (file.deleted) {
    return commitActionTypes.delete;
  } else if (file.tempFile && !file.replaces) {
    return commitActionTypes.create;
  }

  return commitActionTypes.update;
};

export const getCommitFiles = stagedFiles =>
  stagedFiles.reduce((acc, file) => {
    if (file.moved) return acc;

    return acc.concat({
      ...file,
    });
  }, []);

export const createCommitPayload = ({
  branch,
  getters,
  newBranch,
  state,
  rootState,
  rootGetters,
}) => ({
  branch,
  commit_message: state.commitMessage || getters.preBuiltCommitMessage,
  actions: getCommitFiles(rootState.stagedFiles).map(f => ({
    action: commitActionForFile(f),
    file_path: f.moved ? f.movedPath : f.path,
    previous_path: f.prevPath === '' ? undefined : f.prevPath,
    content: f.prevPath ? null : f.content || undefined,
    encoding: f.base64 ? 'base64' : 'text',
    last_commit_id:
      newBranch || f.deleted || f.prevPath || f.replaces ? undefined : f.lastCommitSha,
  })),
  start_sha: newBranch ? rootGetters.lastCommit.short_id : undefined,
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

export const filePathMatches = (filePath, path) => filePath.indexOf(`${path}/`) === 0;

export const getChangesCountForFiles = (files, path) =>
  files.filter(f => filePathMatches(f.path, path)).length;

export const mergeTrees = (fromTree, toTree) => {
  if (!fromTree || !fromTree.length) {
    return toTree;
  }

  const recurseTree = (n, t) => {
    if (!n) {
      return t;
    }
    const existingTreeNode = t.find(el => el.path === n.path);

    if (existingTreeNode && n.tree.length > 0) {
      existingTreeNode.opened = true;
      recurseTree(n.tree[0], existingTreeNode.tree);
    } else if (!existingTreeNode) {
      const sorted = sortTree(t.concat(n));
      t.splice(0, t.length + 1, ...sorted);
    }
    return t;
  };

  for (let i = 0, l = fromTree.length; i < l; i += 1) {
    recurseTree(fromTree[i], toTree);
  }

  return toTree;
};
