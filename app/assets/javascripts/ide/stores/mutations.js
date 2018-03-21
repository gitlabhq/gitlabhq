import * as types from './mutation_types';
import projectMutations from './mutations/project';
import fileMutations from './mutations/file';
import treeMutations from './mutations/tree';
import branchMutations from './mutations/branch';

export default {
  [types.SET_INITIAL_DATA](state, data) {
    Object.assign(state, data);
  },
  [types.TOGGLE_LOADING](state, { entry, forceValue = undefined }) {
    if (entry.path) {
      Object.assign(state.entries[entry.path], {
        loading:
          forceValue !== undefined
            ? forceValue
            : !state.entries[entry.path].loading,
      });
    } else {
      Object.assign(entry, {
        loading: forceValue !== undefined ? forceValue : !entry.loading,
      });
    }
  },
  [types.SET_LEFT_PANEL_COLLAPSED](state, collapsed) {
    Object.assign(state, {
      leftPanelCollapsed: collapsed,
    });
  },
  [types.SET_RIGHT_PANEL_COLLAPSED](state, collapsed) {
    Object.assign(state, {
      rightPanelCollapsed: collapsed,
    });
  },
  [types.SET_RESIZING_STATUS](state, resizing) {
    Object.assign(state, {
      panelResizing: resizing,
    });
  },
  [types.SET_LAST_COMMIT_DATA](state, { entry, lastCommit }) {
    Object.assign(entry.lastCommit, {
      id: lastCommit.commit.id,
      url: lastCommit.commit_path,
      message: lastCommit.commit.message,
      author: lastCommit.commit.author_name,
      updatedAt: lastCommit.commit.authored_date,
    });
  },
  [types.SET_LAST_COMMIT_MSG](state, lastCommitMsg) {
    Object.assign(state, {
      lastCommitMsg,
    });
  },
  [types.CLEAR_STAGED_CHANGES](state) {
    Object.assign(state, {
      stagedFiles: [],
    });
  },
  [types.SET_ENTRIES](state, entries) {
    Object.assign(state, {
      entries,
    });
  },
  [types.CREATE_TMP_ENTRY](state, { data, projectId, branchId }) {
    Object.keys(data.entries).reduce((acc, key) => {
      const entry = data.entries[key];
      const foundEntry = state.entries[key];

      if (!foundEntry) {
        Object.assign(state.entries, {
          [key]: entry,
        });
      } else {
        const tree = entry.tree.filter(
          f => foundEntry.tree.find(e => e.path === f.path) === undefined,
        );
        Object.assign(foundEntry, {
          tree: foundEntry.tree.concat(tree),
        });
      }

      return acc.concat(key);
    }, []);

    const foundEntry = state.trees[`${projectId}/${branchId}`].tree.find(
      e => e.path === data.treeList[0].path,
    );

    if (!foundEntry) {
      Object.assign(state.trees[`${projectId}/${branchId}`], {
        tree: state.trees[`${projectId}/${branchId}`].tree.concat(
          data.treeList,
        ),
      });
    }
  },
  [types.UPDATE_VIEWER](state, viewer) {
    Object.assign(state, {
      viewer,
    });
  },
  [types.UPDATE_DELAY_VIEWER_CHANGE](state, delayViewerUpdated) {
    Object.assign(state, {
      delayViewerUpdated,
    });
  },
  [types.UPDATE_FILE_AFTER_COMMIT](state, { file, lastCommit }) {
    const changedFile = state.changedFiles.find(f => f.path === file.path);

    Object.assign(state.entries[file.path], {
      raw: file.content,
      changed: !!changedFile,
      lastCommit: Object.assign(state.entries[file.path].lastCommit, {
        id: lastCommit.commit.id,
        url: lastCommit.commit_path,
        message: lastCommit.commit.message,
        author: lastCommit.commit.author_name,
        updatedAt: lastCommit.commit.authored_date,
      }),
    });
  },
  ...projectMutations,
  ...fileMutations,
  ...treeMutations,
  ...branchMutations,
};
