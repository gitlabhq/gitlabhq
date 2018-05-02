import $ from 'jquery';
import { sprintf, __ } from '~/locale';
import flash from '~/flash';
import { stripHtml } from '~/lib/utils/text_utility';
import * as rootTypes from '../../mutation_types';
import { createCommitPayload, createNewMergeRequestUrl } from '../../utils';
import router from '../../../ide_router';
import service from '../../../services';
import * as types from './mutation_types';
import * as consts from './constants';
import eventHub from '../../../eventhub';

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

export const setLastCommitMessage = ({ rootState, commit }, data) => {
  const currentProject = rootState.projects[rootState.currentProjectId];
  const commitStats = data.stats
    ? sprintf(__('with %{additions} additions, %{deletions} deletions.'), {
        additions: data.stats.additions, // eslint-disable-line indent
        deletions: data.stats.deletions, // eslint-disable-line indent
      }) // eslint-disable-line indent
    : '';
  const commitMsg = sprintf(
    __('Your changes have been committed. Commit %{commitId} %{commitStats}'),
    {
      commitId: `<a href="${currentProject.web_url}/commit/${data.short_id}" class="commit-sha">${
        data.short_id
      }</a>`,
      commitStats,
    },
    false,
  );

  commit(rootTypes.SET_LAST_COMMIT_MSG, commitMsg, { root: true });
};

export const checkCommitStatus = ({ rootState }) =>
  service
    .getBranchData(rootState.currentProjectId, rootState.currentBranchId)
    .then(({ data }) => {
      const { id } = data.commit;
      const selectedBranch =
        rootState.projects[rootState.currentProjectId].branches[rootState.currentBranchId];

      if (selectedBranch.workingReference !== id) {
        return true;
      }

      return false;
    })
    .catch(() =>
      flash(
        __('Error checking branch data. Please try again.'),
        'alert',
        document,
        null,
        false,
        true,
      ),
    );

export const updateFilesAfterCommit = (
  { commit, dispatch, state, rootState, rootGetters },
  { data, branch },
) => {
  const selectedProject = rootState.projects[rootState.currentProjectId];
  const lastCommit = {
    commit_path: `${selectedProject.web_url}/commit/${data.id}`,
    commit: {
      id: data.id,
      message: data.message,
      authored_date: data.committed_date,
      author_name: data.committer_name,
    },
  };

  commit(
    rootTypes.SET_BRANCH_WORKING_REFERENCE,
    {
      projectId: rootState.currentProjectId,
      branchId: rootState.currentBranchId,
      reference: data.id,
    },
    { root: true },
  );

  rootState.stagedFiles.forEach(file => {
    const changedFile = rootState.changedFiles.find(f => f.path === file.path);

    commit(
      rootTypes.UPDATE_FILE_AFTER_COMMIT,
      {
        file,
        lastCommit,
      },
      { root: true },
    );

    commit(
      rootTypes.TOGGLE_FILE_CHANGED,
      {
        file,
        changed: false,
      },
      { root: true },
    );

    dispatch('updateTempFlagForEntry', { file, tempFile: false }, { root: true });

    eventHub.$emit(`editor.update.model.content.${file.key}`, {
      content: file.content,
      changed: !!changedFile,
    });
  });

  if (state.commitAction === consts.COMMIT_TO_NEW_BRANCH && rootGetters.activeFile) {
    router.push(
      `/project/${rootState.currentProjectId}/blob/${branch}/${rootGetters.activeFile.path}`,
    );
  }
};

export const commitChanges = ({ commit, state, getters, dispatch, rootState }) => {
  const newBranch = state.commitAction !== consts.COMMIT_TO_CURRENT_BRANCH;
  const payload = createCommitPayload(getters.branchName, newBranch, state, rootState);
  const getCommitStatus = newBranch ? Promise.resolve(false) : dispatch('checkCommitStatus');

  commit(types.UPDATE_LOADING, true);

  return getCommitStatus
    .then(
      branchChanged =>
        new Promise(resolve => {
          if (branchChanged) {
            // show the modal with a Bootstrap call
            $('#ide-create-branch-modal').modal('show');
          } else {
            resolve();
          }
        }),
    )
    .then(() => service.commit(rootState.currentProjectId, payload))
    .then(({ data }) => {
      commit(types.UPDATE_LOADING, false);

      if (!data.short_id) {
        flash(data.message, 'alert', document, null, false, true);
        return null;
      }

      dispatch('setLastCommitMessage', data);
      dispatch('updateCommitMessage', '');
      return dispatch('updateFilesAfterCommit', {
        data,
        branch: getters.branchName,
      })
        .then(() => {
          if (state.commitAction === consts.COMMIT_TO_NEW_BRANCH_MR) {
            dispatch(
              'redirectToUrl',
              createNewMergeRequestUrl(
                rootState.projects[rootState.currentProjectId].web_url,
                getters.branchName,
                rootState.currentBranchId,
              ),
              { root: true },
            );
          }

          commit(rootTypes.CLEAR_STAGED_CHANGES, null, { root: true });
        })
        .then(() => dispatch('updateCommitAction', consts.COMMIT_TO_CURRENT_BRANCH));
    })
    .catch(err => {
      let errMsg = __('Error committing changes. Please try again.');
      if (err.response.data && err.response.data.message) {
        errMsg += ` (${stripHtml(err.response.data.message)})`;
      }
      flash(errMsg, 'alert', document, null, false, true);
      window.dispatchEvent(new Event('resize'));

      commit(types.UPDATE_LOADING, false);
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
