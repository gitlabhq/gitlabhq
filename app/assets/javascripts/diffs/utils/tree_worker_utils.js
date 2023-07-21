import { TREE_TYPE } from '../constants';

export const getLowestSingleFolder = (folder) => {
  const getFolder = (blob, start = []) =>
    blob.tree.reduce(
      (acc, file) => {
        const shouldGetFolder = file.tree.length === 1 && file.tree[0].type === TREE_TYPE;
        const currentFileTypeTree = file.type === TREE_TYPE;
        const path = shouldGetFolder || currentFileTypeTree ? acc.path.concat(file.name) : acc.path;
        const tree = shouldGetFolder || currentFileTypeTree ? acc.tree.concat(file) : acc.tree;

        if (shouldGetFolder) {
          const firstFolder = getFolder(file);

          path.push(...firstFolder.path);
          tree.push(...firstFolder.tree);
        }

        return {
          ...acc,
          path,
          tree,
        };
      },
      { path: start, tree: [] },
    );
  const { path, tree } = getFolder(folder, [folder.name]);

  return {
    path: path.join('/'),
    treeAcc: tree.length ? tree[tree.length - 1].tree : null,
  };
};

export const flattenTree = (tree) => {
  const flatten = (blobTree) =>
    blobTree.reduce((acc, file) => {
      const blob = file;
      let treeToFlatten = blob.tree;

      if (file.type === TREE_TYPE && file.tree.length === 1) {
        const { treeAcc, path } = getLowestSingleFolder(file);

        if (treeAcc) {
          blob.name = path;
          treeToFlatten = flatten(treeAcc);
        }
      }

      blob.tree = flatten(treeToFlatten);

      return acc.concat(blob);
    }, []);

  return flatten(tree);
};

export const generateTreeList = (files) => {
  const { treeEntries, tree } = files.reduce(
    (acc, file) => {
      const split = file.new_path.split('/');

      split.forEach((name, i) => {
        let parent = acc.treeEntries[split.slice(0, i).join('/')];
        const path = `${parent ? `${parent.path}/` : ''}${name}`;
        const child = acc.treeEntries[path];

        if (parent && !parent.tree) {
          parent = null;
        }

        if (!child || !child.tree) {
          const type = path === file.new_path ? 'blob' : 'tree';
          acc.treeEntries[path] = {
            key: path,
            path,
            name,
            type,
            tree: [],
          };

          const entry = acc.treeEntries[path];

          if (type === 'blob') {
            Object.assign(entry, {
              changed: true,
              diffLoaded: false,
              diffLoading: false,
              filePaths: {
                old: file.old_path,
                new: file.new_path,
              },
              tempFile: file.new_file,
              deleted: file.deleted_file,
              fileHash: file.file_hash,
              addedLines: file.added_lines,
              removedLines: file.removed_lines,
              parentPath: parent ? `${parent.path}/` : '/',
              submodule: file.submodule,
            });
          } else {
            Object.assign(entry, {
              opened: true,
            });
          }

          (parent ? parent.tree : acc.tree).push(entry);
        }
      });

      return acc;
    },
    { treeEntries: {}, tree: [] },
  );

  return { treeEntries, tree: flattenTree(tree) };
};
