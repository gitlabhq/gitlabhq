import * as types from './mutation_types';
import * as rootTypes from '../../mutation_types';
import service from '../../../services';
import flash from '../../../../flash';
import { stripHtml } from '../../../../lib/utils/text_utility';

export const updateCommitMessage = ({ commit }, message) => {
  commit(types.UPDATE_COMMIT_MESSAGE, message);
};

export const discardDraft = ({ commit }) => {
  commit(types.UPDATE_COMMIT_MESSAGE, '');
};

export const updateCommitAction = ({ commit }, commitAction) => {
  commit(types.UPDATE_COMMIT_ACTION, commitAction);
};

export const updateBranchName = ({ commit }, branchName) => {
  commit(types.UPDATE_NEW_BRANCH_NAME, branchName);
};

export const commitChanges = ({ commit, state, getters, dispatch, rootState }) => {
  const payload = {
    branch: getters.branchName,
    commit_message: state.commitMessage,
    actions: rootState.changedFiles.map(f => ({
      action: f.tempFile ? 'create' : 'update',
      file_path: f.path,
      content: f.content,
      encoding: f.base64 ? 'base64' : 'text',
    })),
    start_branch: undefined,
  };

  commit(types.UPDATE_LOADING, true);

  console.log(payload);

  return;

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
      commit(rootTypes.SET_LAST_COMMIT_MSG, commitMsg, { root: true });

      if (false) {
        dispatch('discardAllChanges', null, { root: true });
        dispatch(
          'redirectToUrl',
          `${selectedProject.web_url}/merge_requests/new?merge_request[source_branch]=${branch}&merge_request[target_branch]=${rottState.currentBranchId}`,
          { root: true },
        );
      } else {
        commit(rootTypes.SET_BRANCH_WORKING_REFERENCE, {
          projectId: state.currentProjectId,
          branchId: state.currentBranchId,
          reference: data.id,
        }, { root: true });

        state.changedFiles.forEach((entry) => {
          commit(rootTypes.SET_LAST_COMMIT_DATA, {
            entry,
            lastCommit,
          }, { root: true });
        });

        dispatch('discardAllChanges', null, { root: true });

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
};
