import { createAlert } from '~/alert';
import { addNumericSuffix } from '~/ide/utils';
import { sprintf, __ } from '~/locale';
import { leftSidebarViews } from '../../../constants';
import eventHub from '../../../eventhub';
import { parseCommitError } from '../../../lib/errors';
import service from '../../../services';
import * as rootTypes from '../../mutation_types';
import { createCommitPayload, createNewMergeRequestUrl } from '../../utils';
import { COMMIT_TO_CURRENT_BRANCH } from './constants';
import * as types from './mutation_types';

export const updateCommitMessage = ({ commit }, message) => {
  commit(types.UPDATE_COMMIT_MESSAGE, message);
};

export const discardDraft = ({ commit }) => {
  commit(types.UPDATE_COMMIT_MESSAGE, '');
};

export const updateCommitAction = ({ commit }, commitAction) => {
  commit(types.UPDATE_COMMIT_ACTION, { commitAction });
};

export const toggleShouldCreateMR = ({ commit }) => {
  commit(types.TOGGLE_SHOULD_CREATE_MR);
};

export const updateBranchName = ({ commit }, branchName) => {
  commit(types.UPDATE_NEW_BRANCH_NAME, branchName);
};

export const addSuffixToBranchName = ({ commit, state }) => {
  const newBranchName = addNumericSuffix(state.newBranchName, true);

  commit(types.UPDATE_NEW_BRANCH_NAME, newBranchName);
};

export const setLastCommitMessage = ({ commit, rootGetters }, data) => {
  const { currentProject } = rootGetters;
  const commitStats = data.stats
    ? sprintf(__('with %{additions} additions, %{deletions} deletions.'), {
        additions: data.stats.additions,
        deletions: data.stats.deletions,
      })
    : '';
  const commitMsg = sprintf(
    __('Your changes have been committed. Commit %{commitId} %{commitStats}'),
    {
      commitId: `<a href="${currentProject.web_url}/-/commit/${data.short_id}" class="commit-sha">${data.short_id}</a>`,
      commitStats,
    },
    false,
  );

  commit(rootTypes.SET_LAST_COMMIT_MSG, commitMsg, { root: true });
};

export const updateFilesAfterCommit = ({ commit, dispatch, rootState, rootGetters }, { data }) => {
  const selectedProject = rootGetters.currentProject;
  const lastCommit = {
    commit_path: `${selectedProject.web_url}/-/commit/${data.id}`,
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

  rootState.stagedFiles.forEach((file) => {
    const changedFile = rootState.changedFiles.find((f) => f.path === file.path);

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
      changed: Boolean(changedFile),
    });
  });
};

export const commitChanges = ({ commit, state, getters, dispatch, rootState, rootGetters }) => {
  // Pull commit options out because they could change
  // During some of the pre and post commit processing
  const { shouldCreateMR, shouldHideNewMrOption, isCreatingNewBranch, branchName } = getters;
  const newBranch = state.commitAction !== COMMIT_TO_CURRENT_BRANCH;
  const stageFilesPromise = rootState.stagedFiles.length
    ? Promise.resolve()
    : dispatch('stageAllChanges', null, { root: true });

  commit(types.CLEAR_ERROR);
  commit(types.UPDATE_LOADING, true);

  return stageFilesPromise
    .then(() => {
      const payload = createCommitPayload({
        branch: branchName,
        newBranch,
        getters,
        state,
        rootState,
        rootGetters,
      });

      return service.commit(rootState.currentProjectId, payload);
    })
    .catch((e) => {
      commit(types.UPDATE_LOADING, false);
      commit(types.SET_ERROR, parseCommitError(e));

      throw e;
    })
    .then(({ data }) => {
      commit(types.UPDATE_LOADING, false);

      if (!data.short_id) {
        createAlert({
          message: data.message,
          fadeTransition: false,
          addBodyClass: true,
        });
        return null;
      }

      if (!data.parent_ids.length) {
        commit(
          rootTypes.TOGGLE_EMPTY_STATE,
          {
            projectPath: rootState.currentProjectId,
            value: false,
          },
          { root: true },
        );
      }

      dispatch('setLastCommitMessage', data);
      dispatch('updateCommitMessage', '');
      return dispatch('updateFilesAfterCommit', {
        data,
        branch: branchName,
      })
        .then(() => {
          commit(rootTypes.CLEAR_STAGED_CHANGES, null, { root: true });

          setTimeout(() => {
            commit(rootTypes.SET_LAST_COMMIT_MSG, '', { root: true });
          }, 5000);

          if (shouldCreateMR && !shouldHideNewMrOption) {
            const { currentProject } = rootGetters;
            const targetBranch = isCreatingNewBranch
              ? rootState.currentBranchId
              : currentProject.default_branch;

            dispatch(
              'redirectToUrl',
              createNewMergeRequestUrl(
                currentProject.web_url,
                encodeURIComponent(branchName),
                encodeURIComponent(targetBranch),
              ),
              { root: true },
            );
          }
        })
        .then(() => {
          if (rootGetters.lastOpenedFile) {
            dispatch(
              'openPendingTab',
              {
                file: rootGetters.lastOpenedFile,
              },
              { root: true },
            )
              .then((changeViewer) => {
                if (changeViewer) {
                  dispatch('updateViewer', 'diff', { root: true });
                }
              })
              .catch((e) => {
                throw e;
              });
          } else {
            dispatch('updateActivityBarView', leftSidebarViews.edit.name, { root: true });
            dispatch('updateViewer', 'editor', { root: true });
          }
        })
        .then(() => dispatch('updateCommitAction', COMMIT_TO_CURRENT_BRANCH))
        .then(() => {
          if (newBranch) {
            const path = rootGetters.activeFile ? rootGetters.activeFile.path : '';

            return dispatch(
              'router/push',
              `/project/${rootState.currentProjectId}/blob/${branchName}/-/${path}`,
              { root: true },
            );
          }

          return dispatch(
            'refreshLastCommitData',
            { projectId: rootState.currentProjectId, branchId: branchName },
            { root: true },
          );
        });
    });
};
