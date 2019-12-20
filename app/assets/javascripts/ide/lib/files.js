import { viewerInformationForPath } from '~/vue_shared/components/content_viewer/lib/viewer_utils';
import { escapeFileUrl } from '~/lib/utils/url_utility';
import { decorateData, sortTree } from '../stores/utils';

export const splitParent = path => {
  const idx = path.lastIndexOf('/');

  return {
    parent: idx >= 0 ? path.substring(0, idx) : null,
    name: idx >= 0 ? path.substring(idx + 1) : path,
  };
};

/**
 * Create file objects from a list of file paths.
 */
export const decorateFiles = ({
  data,
  projectId,
  branchId,
  tempFile = false,
  content = '',
  base64 = false,
  binary = false,
  rawPath = '',
}) => {
  const treeList = [];
  const entries = {};

  // These mutable variable references end up being exported and used by `createTempEntry`
  let file;
  let parentPath;

  const insertParent = path => {
    if (!path) {
      return null;
    } else if (entries[path]) {
      return entries[path];
    }

    const { parent, name } = splitParent(path);
    const parentFolder = parent && insertParent(parent);
    parentPath = parentFolder && parentFolder.path;

    const tree = decorateData({
      projectId,
      branchId,
      id: path,
      name,
      path,
      url: `/${projectId}/tree/${branchId}/-/${escapeFileUrl(path)}/`,
      type: 'tree',
      parentTreeUrl: parentFolder ? parentFolder.url : `/${projectId}/tree/${branchId}/`,
      tempFile,
      changed: tempFile,
      opened: tempFile,
      parentPath,
    });

    Object.assign(entries, {
      [path]: tree,
    });

    if (parentFolder) {
      parentFolder.tree.push(tree);
    } else {
      treeList.push(tree);
    }

    return tree;
  };

  data.forEach(path => {
    const { parent, name } = splitParent(path);

    const fileFolder = parent && insertParent(parent);

    if (name) {
      const previewMode = viewerInformationForPath(name);
      parentPath = fileFolder && fileFolder.path;

      file = decorateData({
        projectId,
        branchId,
        id: path,
        name,
        path,
        url: `/${projectId}/blob/${branchId}/-/${escapeFileUrl(path)}`,
        type: 'blob',
        parentTreeUrl: fileFolder ? fileFolder.url : `/${projectId}/blob/${branchId}`,
        tempFile,
        changed: tempFile,
        content,
        base64,
        binary: (previewMode && previewMode.binary) || binary,
        rawPath,
        previewMode,
        parentPath,
      });

      Object.assign(entries, {
        [path]: file,
      });

      if (fileFolder) {
        fileFolder.tree.push(file);
      } else {
        treeList.push(file);
      }
    }
  });

  return {
    entries,
    treeList: sortTree(treeList),
    file,
    parentPath,
  };
};
