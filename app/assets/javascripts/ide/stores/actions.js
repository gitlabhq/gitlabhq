import Vue from 'vue';
import { visitUrl } from '../../lib/utils/url_utility';
import flash from '../../flash';
import service from '../services';
import * as types from './mutation_types';
import { stripHtml } from '../../lib/utils/text_utility';

export const redirectToUrl = (_, url) => visitUrl(url);

export const setInitialData = ({ commit }, data) =>
  commit(types.SET_INITIAL_DATA, data);

export const discardAllChanges = ({ state, commit, dispatch }) => {
  state.changedFiles.forEach((file) => {
    commit(types.DISCARD_FILE_CHANGES, file);

    if (file.tempFile) {
      dispatch('closeFile', file);
    }
  });

  commit(types.REMOVE_ALL_CHANGES_FILES);
};

export const closeAllFiles = ({ state, dispatch }) => {
  state.openFiles.forEach(file => dispatch('closeFile', file));
};

export const toggleEditMode = ({ commit, dispatch }) => {
  commit(types.TOGGLE_EDIT_MODE);
  dispatch('toggleBlobView');
};

export const toggleBlobView = ({ commit, state }) => {
  if (state.editMode) {
    commit(types.SET_EDIT_MODE);
  } else {
    commit(types.SET_PREVIEW_MODE);
  }
};

export const setPanelCollapsedStatus = ({ commit }, { side, collapsed }) => {
  if (side === 'left') {
    commit(types.SET_LEFT_PANEL_COLLAPSED, collapsed);
  } else {
    commit(types.SET_RIGHT_PANEL_COLLAPSED, collapsed);
  }
};

export const setResizingStatus = ({ commit }, resizing) => {
  commit(types.SET_RESIZING_STATUS, resizing);
};

export const checkCommitStatus = ({ state }) =>
  service
    .getBranchData(state.currentProjectId, state.currentBranchId)
    .then(({ data }) => {
      const { id } = data.commit;
      const selectedBranch =
        state.projects[state.currentProjectId].branches[state.currentBranchId];

      if (selectedBranch.workingReference !== id) {
        return true;
      }

      return false;
    })
    .catch(() => flash('Error checking branch data. Please try again.', 'alert', document, null, false, true));

export const commitChanges = (
  { commit, state, dispatch },
  { payload, newMr },
) =>
  service
    .commit(state.currentProjectId, payload)
    .then(({ data }) => {
      const { branch } = payload;
      if (!data.short_id) {
        flash(data.message, 'alert', document, null, false, true);
        return;
      }

      const selectedProject = state.projects[state.currentProjectId];
      const lastCommit = {
        commit_path: `${selectedProject.web_url}/commit/${data.id}`,
        commit: {
          message: data.message,
          authored_date: data.committed_date,
        },
      };

      let commitMsg = `Your changes have been committed. Commit ${data.short_id}`;
      if (data.stats) {
        commitMsg += ` with ${data.stats.additions} additions, ${data.stats.deletions} deletions.`;
      }
      commit(types.SET_LAST_COMMIT_MSG, commitMsg);

      if (newMr) {
        dispatch('discardAllChanges');
        dispatch(
          'redirectToUrl',
          `${selectedProject.web_url}/merge_requests/new?merge_request%5Bsource_branch%5D=${branch}`,
        );
      } else {
        commit(types.SET_BRANCH_WORKING_REFERENCE, {
          projectId: state.currentProjectId,
          branchId: state.currentBranchId,
          reference: data.id,
        });

        state.changedFiles.forEach((entry) => {
          commit(types.SET_LAST_COMMIT_DATA, {
            entry,
            lastCommit,
          });
        });

        dispatch('discardAllChanges');

        window.scrollTo(0, 0);
      }
    })
    .catch((err) => {
      let errMsg = 'Error committing changes. Please try again.';
      if (err.response.data && err.response.data.message) {
        errMsg += ` (${stripHtml(err.response.data.message)})`;
      }
      flash(errMsg, 'alert', document, null, false, true);
      window.dispatchEvent(new Event('resize'));
    });

export const createTempEntry = (
  { state, dispatch },
  { projectId, branchId, parent, name, type, content = '', base64 = false },
) => {
  const selectedParent = parent || state.trees[`${projectId}/${branchId}`];
  if (type === 'tree') {
    dispatch('createTempTree', {
      projectId,
      branchId,
      parent: selectedParent,
      name,
    });
  } else if (type === 'blob') {
    dispatch('createTempFile', {
      projectId,
      branchId,
      parent: selectedParent,
      name,
      base64,
      content,
    });
  }
};

export const scrollToTab = () => {
  Vue.nextTick(() => {
    const tabs = document.getElementById('tabs');

    if (tabs) {
      const tabEl = tabs.querySelector('.active .repo-tab');

      tabEl.focus();
    }
  });
};

export * from './actions/tree';
export * from './actions/file';
export * from './actions/project';
export * from './actions/branch';
