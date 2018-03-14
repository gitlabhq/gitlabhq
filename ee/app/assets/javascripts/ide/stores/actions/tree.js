import { visitUrl } from '~/lib/utils/url_utility';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import flash from '~/flash';
import service from '../../services';
import * as types from '../mutation_types';
import router from '../../ide_router';
import {
  setPageTitle,
  findEntry,
  createTemp,
  createOrMergeEntry,
  sortTree,
} from '../utils';

export const getTreeData = (
  { commit, state, dispatch },
  { endpoint, tree = null, projectId, branch, force = false } = {},
) => new Promise((resolve, reject) => {
  // We already have the base tree so we resolve immediately
  if (!tree && state.trees[`${projectId}/${branch}`] && !force) {
    resolve();
  } else {
    if (tree) commit(types.TOGGLE_LOADING, { entry: tree });
    const selectedProject = state.projects[projectId];
    // We are merging the web_url that we got on the project info with the endpoint
    // we got on the tree entry, as both contain the projectId, we replace it in the tree endpoint
    const completeEndpoint = selectedProject.web_url + (endpoint).replace(projectId, '');
    if (completeEndpoint && (!tree || !tree.tempFile)) {
      service.getTreeData(completeEndpoint)
      .then((res) => {
        const pageTitle = decodeURI(normalizeHeaders(res.headers)['PAGE-TITLE']);

        setPageTitle(pageTitle);

        return res.json();
      })
      .then((data) => {
        dispatch('updateDirectoryData', { data, tree, projectId, branch, clearTree: false });
        const selectedTree = tree || state.trees[`${projectId}/${branch}`];

        commit(types.SET_PARENT_TREE_URL, data.parent_tree_url);
        commit(types.SET_LAST_COMMIT_URL, { tree: selectedTree, url: data.last_commit_path });
        if (tree) commit(types.TOGGLE_LOADING, { entry: selectedTree });

        const prevLastCommitPath = selectedTree.lastCommitPath;
        if (prevLastCommitPath !== null) {
          dispatch('getLastCommitData', selectedTree);
        }
        resolve(data);
      })
      .catch((e) => {
        flash('Error loading tree data. Please try again.', 'alert', document, null, false, true);
        if (tree) commit(types.TOGGLE_LOADING, { entry: tree });
        reject(e);
      });
    } else {
      resolve();
    }
  }
});

export const toggleTreeOpen = ({ commit, dispatch }, { tree }) => {
  commit(types.TOGGLE_TREE_OPEN, tree);
};

export const handleTreeEntryAction = ({ commit, dispatch }, row) => {
  if (row.type === 'tree') {
    dispatch('toggleTreeOpen', {
      endpoint: row.url,
      tree: row,
    });
  } else if (row.type === 'submodule') {
    commit(types.TOGGLE_LOADING, { entry: row });
    visitUrl(row.url);
  } else if (row.type === 'blob' && (row.opened || row.changed)) {
    if (row.changed && !row.opened) {
      commit(types.TOGGLE_FILE_OPEN, row);
    }

    dispatch('setFileActive', row);
  } else {
    dispatch('getFileData', row);
  }
};

export const createTempTree = (
  { state, commit, dispatch },
  { projectId, branchId, parent, name },
) => {
  let selectedTree = parent;
  const dirNames = name.replace(new RegExp(`^${state.path}/`), '').split('/');

  dirNames.forEach((dirName) => {
    const foundEntry = findEntry(selectedTree.tree, 'tree', dirName);

    if (!foundEntry) {
      const path = selectedTree.path !== undefined ? selectedTree.path : '';
      const tmpEntry = createTemp({
        projectId,
        branchId,
        name: dirName,
        path,
        type: 'tree',
        level: selectedTree.level !== undefined ? selectedTree.level + 1 : 0,
        tree: [],
        url: `/${projectId}/blob/${branchId}/${path}${path ? '/' : ''}${dirName}`,
      });

      commit(types.CREATE_TMP_TREE, {
        parent: selectedTree,
        tmpEntry,
      });
      commit(types.TOGGLE_TREE_OPEN, tmpEntry);

      router.push(`/project${tmpEntry.url}`);

      selectedTree = tmpEntry;
    } else {
      selectedTree = foundEntry;
    }
  });
};

export const getLastCommitData = ({ state, commit, dispatch, getters }, tree = state) => {
  if (!tree || tree.lastCommitPath === null || !tree.lastCommitPath) return;

  service.getTreeLastCommit(tree.lastCommitPath)
    .then((res) => {
      const lastCommitPath = normalizeHeaders(res.headers)['MORE-LOGS-URL'] || null;

      commit(types.SET_LAST_COMMIT_URL, { tree, url: lastCommitPath });

      return res.json();
    })
    .then((data) => {
      data.forEach((lastCommit) => {
        const entry = findEntry(tree.tree, lastCommit.type, lastCommit.file_name);

        if (entry) {
          commit(types.SET_LAST_COMMIT_DATA, { entry, lastCommit });
        }
      });

      dispatch('getLastCommitData', tree);
    })
    .catch(() => flash('Error fetching log data.', 'alert', document, null, false, true));
};

export const updateDirectoryData = (
  { commit, state },
  { data, tree, projectId, branch, clearTree = true },
) => {
  if (!tree) {
    const existingTree = state.trees[`${projectId}/${branch}`];
    if (!existingTree) {
      commit(types.CREATE_TREE, { treePath: `${projectId}/${branch}` });
    }
  }

  const selectedTree = tree || state.trees[`${projectId}/${branch}`];
  const level = selectedTree.level !== undefined ? selectedTree.level + 1 : 0;
  const parentTreeUrl = data.parent_tree_url ? `${data.parent_tree_url}${data.path}` : state.endpoints.rootUrl;
  const createEntry = (entry, type) => createOrMergeEntry({
    projectId: `${projectId}`,
    branchId: branch,
    entry,
    level,
    type,
    parentTreeUrl,
    state,
  });

  let formattedData = [
    ...data.trees.map(t => createEntry(t, 'tree')),
    ...data.submodules.map(m => createEntry(m, 'submodule')),
    ...data.blobs.map(b => createEntry(b, 'blob')),
  ];

  if (!clearTree && tree) {
    const tempFiles = state.changedFiles.filter(f => f.tempFile && f.path === `${tree.path}/${f.name}`);

    if (tempFiles.length) {
      formattedData = formattedData.concat(tempFiles);
    }
  }

  commit(types.SET_DIRECTORY_DATA, { tree: selectedTree, data: formattedData });
};

export const getFiles = (
  { state, commit, dispatch },
  { projectId, branchId } = {},
) => new Promise((resolve, reject) => {
  if (!state.trees[`${projectId}/${branchId}`]) {
    const selectedProject = state.projects[projectId];
    commit(types.CREATE_TREE, { treePath: `${projectId}/${branchId}` });

    service
      .getFiles(selectedProject.web_url, branchId)
      .then(res => res.json())
      .then((data) => {
        const newTree = data.reduce((outputArray, file) => {
          const pathSplit = file.split('/');
          const blobName = pathSplit.pop();
          let selectedFolderTree;
          let foundFolder = null;
          let fullPath = '';

          if (pathSplit.length > 0) {
            const newBaseFolders = pathSplit.reduce((newFolders, folder, currentIndex) => {
              fullPath += `/${folder}`;
              foundFolder = findEntry(selectedFolderTree || outputArray, 'tree', fullPath, 'path');
              if (!foundFolder) {
                foundFolder = createOrMergeEntry({
                  projectId,
                  branchId,
                  entry: {
                    id: fullPath,
                    name: folder,
                    path: fullPath,
                    url: `/${projectId}/tree/${branchId}/${fullPath}`,
                  },
                  level: currentIndex,
                  type: 'tree',
                  parentTreeUrl: '',
                  state,
                });

                if (selectedFolderTree) {
                  selectedFolderTree.push(foundFolder);
                } else {
                  newFolders.push(foundFolder);
                }
              }
              selectedFolderTree = foundFolder.tree;
              return newFolders;
            }, []);
            if (newBaseFolders.length) outputArray.push(newBaseFolders[0]);
          }

          // Add file
          const blobEntry = createOrMergeEntry({
            projectId,
            branchId,
            entry: {
              id: file,
              name: blobName,
              path: file,
              url: `/${projectId}/blob/${branchId}/${file}`,
            },
            level: foundFolder ? (foundFolder.level + 1) : 0,
            type: 'blob',
            parentTreeUrl: foundFolder ? foundFolder.url : '',
            state,
          });

          if (selectedFolderTree) {
            selectedFolderTree.push(blobEntry);
          } else {
            outputArray.push(blobEntry);
          }

          return outputArray;
        }, []);

        const selectedTree = state.trees[`${projectId}/${branchId}`];
        commit(types.SET_DIRECTORY_DATA, { tree: selectedTree, data: sortTree(newTree) });
        commit(types.TOGGLE_LOADING, { entry: selectedTree, forceValue: false });

        resolve();
      })
      .catch((e) => {
        flash('Error loading tree data. Please try again.', 'alert', document, null, false, true);
        reject(e);
      });
  } else {
    resolve();
  }
});

