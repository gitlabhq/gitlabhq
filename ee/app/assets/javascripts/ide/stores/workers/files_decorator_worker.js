import {
  decorateData,
  sortTree,
} from '../utils';

self.addEventListener('message', (e) => {
  const { data, projectId, branchId } = e.data;

  const treeList = [];
  const entries = data.reduce((acc, path) => {
    const pathSplit = path.split('/');
    const blobName = pathSplit.pop();

    if (pathSplit.length > 0) {
      pathSplit.reduce((pathAcc, folderName, folderLevel) => {
        const parentFolder = acc[pathAcc[pathAcc.length - 1]];
        const folderPath = `${(parentFolder ? `${parentFolder.path}/` : '')}${folderName}`;
        const foundEntry = acc[folderPath];

        if (!foundEntry) {
          const tree = decorateData({
            projectId,
            branchId,
            id: folderPath,
            name: folderName,
            path: folderPath,
            url: `/${projectId}/tree/${branchId}/${folderPath}`,
            level: parentFolder ? parentFolder.level + 1 : folderLevel,
            type: 'tree',
            parentTreeUrl: parentFolder ? parentFolder.url : `/${projectId}/tree/${branchId}/`,
          });

          Object.assign(acc, {
            [folderPath]: tree,
          });

          if (parentFolder) {
            parentFolder.tree.push(tree);
          } else {
            treeList.push(tree);
          }

          pathAcc.push(tree.path);
        } else {
          pathAcc.push(foundEntry.path);
        }

        return pathAcc;
      }, []);
    }

    const fileFolder = acc[pathSplit.join('/')];
    const file = decorateData({
      projectId,
      branchId,
      id: path,
      name: blobName,
      path,
      url: `/${projectId}/blob/${branchId}/${path}`,
      level: fileFolder ? fileFolder.level + 1 : 0,
      type: 'blob',
      parentTreeUrl: fileFolder ? fileFolder.url : `/${projectId}/blob/${branchId}`,
    });

    Object.assign(acc, {
      [path]: file,
    });

    if (fileFolder) {
      fileFolder.tree.push(file);
    } else {
      treeList.push(file);
    }

    return acc;
  }, {});

  self.postMessage({
    entries,
    treeList: sortTree(treeList),
  });
});
