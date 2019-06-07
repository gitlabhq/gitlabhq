import $ from 'jquery';
import { sprintf, __ } from '~/locale';
import flash from '~/flash';
import * as rootTypes from '../../mutation_types';
import { createCommitPayload, createNewMergeRequestUrl } from '../../utils';
import router from '../../../ide_router';
import service from '../../../services';
import * as types from './mutation_types';
import consts from './constants';
import { activityBarViews } from '../../../constants';
import eventHub from '../../../eventhub';

export const updateCommitMessage = ({ commit }, message) => {
  commit(types.UPDATE_COMMIT_MESSAGE, message);
};

export const discardDraft = ({ commit }) => {
  commit(types.UPDATE_COMMIT_MESSAGE, '');
};

export const updateCommitAction = ({ commit, dispatch }, commitAction) => {
  commit(types.UPDATE_COMMIT_ACTION, {
    commitAction,
  });
  dispatch('setShouldCreateMR');
};

export const toggleShouldCreateMR = ({ commit }) => {
  commit(types.TOGGLE_SHOULD_CREATE_MR);
  commit(types.INTERACT_WITH_NEW_MR);
};

export const setShouldCreateMR = ({
  commit,
  getters,
  rootGetters,
  state: { interactedWithNewMR },
}) => {
  const committingToExistingMR =
    getters.isCommittingToCurrentBranch &&
    rootGetters.hasMergeRequest &&
    !rootGetters.isOnDefaultBranch;

  if ((getters.isCommittingToDefaultBranch && !interactedWithNewMR) || committingToExistingMR) {
    commit(types.TOGGLE_SHOULD_CREATE_MR, false);
  } else if (!interactedWithNewMR) {
    commit(types.TOGGLE_SHOULD_CREATE_MR, true);
  }
};

export const updateBranchName = ({ commit }, branchName) => {
  commit(types.UPDATE_NEW_BRANCH_NAME, branchName);
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
      commitId: `<a href="${currentProject.web_url}/commit/${data.short_id}" class="commit-sha">${
        data.short_id
      }</a>`,
      commitStats,
    },
    false,
  );

  commit(rootTypes.SET_LAST_COMMIT_MSG, commitMsg, { root: true });
};

export const updateFilesAfterCommit = ({ commit, dispatch, rootState, rootGetters }, { data }) => {
  const selectedProject = rootGetters.currentProject;
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
      changed: Boolean(changedFile),
    });
  });
};

export const commitChanges = ({ commit, state, getters, dispatch, rootState, rootGetters }) => {
  const newBranch = state.commitAction !== consts.COMMIT_TO_CURRENT_BRANCH;
  const stageFilesPromise = rootState.stagedFiles.length
    ? Promise.resolve()
    : dispatch('stageAllChanges', null, { root: true });

  commit(types.UPDATE_LOADING, true);

  return stageFilesPromise
    .then(() => {
      const payload = createCommitPayload({
        branch: getters.branchName,
        newBranch,
        getters,
        state,
        rootState,
      });

      return service.commit(rootState.currentProjectId, payload);
    })
    .then(({ data }) => {
      commit(types.UPDATE_LOADING, false);

      if (!data.short_id) {
        flash(data.message, 'alert', document, null, false, true);
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
        branch: getters.branchName,
      })
        .then(() => {
          if (state.shouldCreateMR) {
            const { currentProject } = rootGetters;
            const targetBranch = getters.isCreatingNewBranch
              ? rootState.currentBranchId
              : currentProject.default_branch;

            dispatch(
              'redirectToUrl',
              createNewMergeRequestUrl(currentProject.web_url, getters.branchName, targetBranch),
              { root: true },
            );
          }

          commit(rootTypes.CLEAR_STAGED_CHANGES, null, { root: true });

          setTimeout(() => {
            commit(rootTypes.SET_LAST_COMMIT_MSG, '', { root: true });
          }, 5000);
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
              .then(changeViewer => {
                if (changeViewer) {
                  dispatch('updateViewer', 'diff', { root: true });
                }
              })
              .catch(e => {
                throw e;
              });
          } else {
            dispatch('updateActivityBarView', activityBarViews.edit, { root: true });
            dispatch('updateViewer', 'editor', { root: true });

            if (rootGetters.activeFile) {
              router.push(
                `/project/${rootState.currentProjectId}/blob/${getters.branchName}/-/${
                  rootGetters.activeFile.path
                }`,
              );
            }
          }
        })
        .then(() => dispatch('updateCommitAction', consts.COMMIT_TO_CURRENT_BRANCH))
        .then(() =>
          dispatch(
            'refreshLastCommitData',
            {
              projectId: rootState.currentProjectId,
              branchId: rootState.currentBranchId,
            },
            { root: true },
          ),
        );
    })
    .catch(err => {
      if (err.response.status === 400) {
        $('#ide-create-branch-modal').modal('show');
      } else {
        dispatch(
          'setErrorMessage',
          {
            text: __('An error occurred whilst committing your changes.'),
            action: () =>
              dispatch('commitChanges').then(() =>
                dispatch('setErrorMessage', null, { root: true }),
              ),
            actionText: __('Please try again'),
          },
          { root: true },
        );
        window.dispatchEvent(new Event('resize'));
      }

      commit(types.UPDATE_LOADING, false);
    });
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
