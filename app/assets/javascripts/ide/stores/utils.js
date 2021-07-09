import {
  relativePathToAbsolute,
  isAbsolute,
  isRootRelative,
  isBlobUrl,
} from '~/lib/utils/url_utility';
import { commitActionTypes } from '../constants';

export const dataStructure = () => ({
  id: '',
  // Key will contain a mixture of ID and path
  // it can also contain a prefix `pending-` for files opened in review mode
  key: '',
  type: '',
  name: '',
  path: '',
  tempFile: false,
  tree: [],
  loading: false,
  opened: false,
  active: false,
  changed: false,
  staged: false,
  lastCommitSha: '',
  rawPath: '',
  raw: '',
  content: '',
  size: 0,
  parentPath: null,
  lastOpenedAt: 0,
  mrChange: null,
  deleted: false,
  prevPath: undefined,
  mimeType: '',
});

export const decorateData = (entity) => {
  const {
    id,
    type,
    name,
    path,
    content = '',
    tempFile = false,
    active = false,
    opened = false,
    changed = false,
    rawPath = '',
    file_lock,
    parentPath = '',
    mimeType = '',
  } = entity;

  return Object.assign(dataStructure(), {
    id,
    key: `${name}-${type}-${id}`,
    type,
    name,
    path,
    tempFile,
    opened,
    active,
    changed,
    content,
    rawPath,
    file_lock,
    parentPath,
    mimeType,
  });
};

export const setPageTitle = (title) => {
  document.title = title;
};

export const setPageTitleForFile = (state, file) => {
  const title = [file.path, state.currentBranchId, state.currentProjectId, 'GitLab'].join(' · ');
  setPageTitle(title);
};

export const commitActionForFile = (file) => {
  if (file.prevPath) {
    return commitActionTypes.move;
  } else if (file.deleted) {
    return commitActionTypes.delete;
  } else if (file.tempFile) {
    return commitActionTypes.create;
  }

  return commitActionTypes.update;
};

export const getCommitFiles = (stagedFiles) =>
  stagedFiles.reduce((acc, file) => {
    if (file.type === 'tree') return acc;

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
  actions: getCommitFiles(rootState.stagedFiles).map((f) => {
    const isBlob = isBlobUrl(f.rawPath);
    const content = isBlob ? btoa(f.content) : f.content;

    return {
      action: commitActionForFile(f),
      file_path: f.path,
      previous_path: f.prevPath || undefined,
      content: f.prevPath && !f.changed ? null : content || undefined,
      encoding: isBlob ? 'base64' : 'text',
      last_commit_id: newBranch || f.deleted || f.prevPath ? undefined : f.lastCommitSha,
    };
  }),
  start_sha: newBranch ? rootGetters.lastCommit.id : undefined,
});

export const createNewMergeRequestUrl = (projectUrl, source, target) =>
  `${projectUrl}/-/merge_requests/new?merge_request[source_branch]=${source}&merge_request[target_branch]=${target}&nav_source=webide`;

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

export const sortTree = (sortedTree) =>
  sortedTree
    .map((entity) =>
      Object.assign(entity, {
        tree: entity.tree.length ? sortTree(entity.tree) : [],
      }),
    )
    .sort(sortTreesByTypeAndName);

export const filePathMatches = (filePath, path) => filePath.indexOf(`${path}/`) === 0;

export const getChangesCountForFiles = (files, path) =>
  files.filter((f) => filePathMatches(f.path, path)).length;

export const mergeTrees = (fromTree, toTree) => {
  if (!fromTree || !fromTree.length) {
    return toTree;
  }

  const recurseTree = (n, t) => {
    if (!n) {
      return t;
    }
    const existingTreeNode = t.find((el) => el.path === n.path);

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

export const swapInStateArray = (state, arr, key, entryPath) =>
  Object.assign(state, {
    [arr]: state[arr].map((f) => (f.key === key ? state.entries[entryPath] : f)),
  });

export const getEntryOrRoot = (state, path) =>
  path ? state.entries[path] : state.trees[`${state.currentProjectId}/${state.currentBranchId}`];

export const swapInParentTreeWithSorting = (state, oldKey, newPath, parentPath) => {
  if (!newPath) {
    return;
  }

  const parent = getEntryOrRoot(state, parentPath);

  if (parent) {
    const tree = parent.tree
      // filter out old entry && new entry
      .filter(({ key, path }) => key !== oldKey && path !== newPath)
      // concat new entry
      .concat(state.entries[newPath]);

    parent.tree = sortTree(tree);
  }
};

export const removeFromParentTree = (state, oldKey, parentPath) => {
  const parent = getEntryOrRoot(state, parentPath);

  if (parent) {
    parent.tree = sortTree(parent.tree.filter(({ key }) => key !== oldKey));
  }
};

export const updateFileCollections = (state, key, entryPath) => {
  ['openFiles', 'changedFiles', 'stagedFiles'].forEach((fileCollection) => {
    swapInStateArray(state, fileCollection, key, entryPath);
  });
};

export const cleanTrailingSlash = (path) => path.replace(/\/$/, '');

export const pathsAreEqual = (a, b) => {
  const cleanA = a ? cleanTrailingSlash(a) : '';
  const cleanB = b ? cleanTrailingSlash(b) : '';

  return cleanA === cleanB;
};

export function extractMarkdownImagesFromEntries(mdFile, entries) {
  /**
   * Regex to identify an image tag in markdown, like:
   *
   * ![img alt goes here](/img.png)
   * ![img alt](../img 1/img.png "my image title")
   * ![img alt](https://gitlab.com/assets/logo.svg "title here")
   *
   */
  const reMdImage = /!\[([^\]]*)\]\((.*?)(?:(?="|\))"([^"]*)")?\)/gi;
  const prefix = 'gl_md_img_';
  const images = {};

  let content = mdFile.content || mdFile.raw;
  let i = 0;

  content = content.replace(reMdImage, (_, alt, path, title) => {
    const imagePath = (isRootRelative(path) ? path : relativePathToAbsolute(path, mdFile.path))
      .substr(1)
      .trim();

    const imageContent = entries[imagePath]?.content || entries[imagePath]?.raw;
    const imageRawPath = entries[imagePath]?.rawPath;

    if (!isAbsolute(path) && imageContent) {
      const src = imageRawPath;
      i += 1;
      const key = `{{${prefix}${i}}}`;
      images[key] = { alt, src, title };
      return key;
    }
    return title ? `![${alt}](${path}"${title}")` : `![${alt}](${path})`;
  });

  return { content, images };
}
