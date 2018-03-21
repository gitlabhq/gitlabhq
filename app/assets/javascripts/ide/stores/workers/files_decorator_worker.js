<<<<<<< HEAD
import {
  decorateData,
  sortTree,
} from '../utils';

self.addEventListener('message', (e) => {
  const { data, projectId, branchId, tempFile = false, content = '', base64 = false } = e.data;
=======
import { decorateData, sortTree } from '../utils';

self.addEventListener('message', e => {
  const {
    data,
    projectId,
    branchId,
    tempFile = false,
    content = '',
    base64 = false,
  } = e.data;
>>>>>>> upstream/master

  const treeList = [];
  let file;
  const entries = data.reduce((acc, path) => {
    const pathSplit = path.split('/');
    const blobName = pathSplit.pop().trim();

    if (pathSplit.length > 0) {
      pathSplit.reduce((pathAcc, folderName) => {
        const parentFolder = acc[pathAcc[pathAcc.length - 1]];
<<<<<<< HEAD
        const folderPath = `${(parentFolder ? `${parentFolder.path}/` : '')}${folderName}`;
=======
        const folderPath = `${
          parentFolder ? `${parentFolder.path}/` : ''
        }${folderName}`;
>>>>>>> upstream/master
        const foundEntry = acc[folderPath];

        if (!foundEntry) {
          const tree = decorateData({
            projectId,
            branchId,
            id: folderPath,
            name: folderName,
            path: folderPath,
<<<<<<< HEAD
            url: `/${projectId}/tree/${branchId}/${folderPath}`,
            type: 'tree',
            parentTreeUrl: parentFolder ? parentFolder.url : `/${projectId}/tree/${branchId}/`,
=======
            url: `/${projectId}/tree/${branchId}/${folderPath}/`,
            type: 'tree',
            parentTreeUrl: parentFolder
              ? parentFolder.url
              : `/${projectId}/tree/${branchId}/`,
>>>>>>> upstream/master
            tempFile,
            changed: tempFile,
            opened: tempFile,
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

    if (blobName !== '') {
      const fileFolder = acc[pathSplit.join('/')];
      file = decorateData({
        projectId,
        branchId,
        id: path,
        name: blobName,
        path,
        url: `/${projectId}/blob/${branchId}/${path}`,
        type: 'blob',
<<<<<<< HEAD
        parentTreeUrl: fileFolder ? fileFolder.url : `/${projectId}/blob/${branchId}`,
=======
        parentTreeUrl: fileFolder
          ? fileFolder.url
          : `/${projectId}/blob/${branchId}`,
>>>>>>> upstream/master
        tempFile,
        changed: tempFile,
        content,
        base64,
      });

      Object.assign(acc, {
        [path]: file,
      });

      if (fileFolder) {
        fileFolder.tree.push(file);
      } else {
        treeList.push(file);
      }
    }

    return acc;
  }, {});

  self.postMessage({
    entries,
    treeList: sortTree(treeList),
    file,
  });
});
