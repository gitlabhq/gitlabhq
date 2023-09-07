import { decorateData, sortTree } from '../stores/utils';

export const splitParent = (path) => {
  const idx = path.lastIndexOf('/');

  return {
    parent: idx >= 0 ? path.substring(0, idx) : null,
    name: idx >= 0 ? path.substring(idx + 1) : path,
  };
};

/**
 * Create file objects from a list of file paths.
 *
 * @param {Array} options.data Array of blob paths to parse and create a file tree from.
 * @param {Boolean} options.tempFile Web IDE flag for whether this is a "new" file or not.
 * @param {String} options.content Content to initialize the new blob with.
 * @param {String} options.rawPath Raw path used for the new blob.
 * @param {Object} options.blobData Extra values to initialize each blob with.
 */
export const decorateFiles = ({
  data,
  tempFile = false,
  content = '',
  rawPath = '',
  blobData = {},
}) => {
  const treeList = [];
  const entries = {};

  // These mutable variable references end up being exported and used by `createTempEntry`
  let file;
  let parentPath;

  const insertParent = (path) => {
    if (!path) {
      return null;
    }
    if (entries[path]) {
      return entries[path];
    }

    const { parent, name } = splitParent(path);
    const parentFolder = parent && insertParent(parent);
    parentPath = parentFolder && parentFolder.path;

    const tree = decorateData({
      id: path,
      name,
      path,
      type: 'tree',
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

  data.forEach((path) => {
    const { parent, name } = splitParent(path);

    const fileFolder = parent && insertParent(parent);

    if (name) {
      parentPath = fileFolder && fileFolder.path;

      file = decorateData({
        id: path,
        name,
        path,
        type: 'blob',
        tempFile,
        changed: tempFile,
        content,
        rawPath,
        parentPath,
        ...blobData,
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
