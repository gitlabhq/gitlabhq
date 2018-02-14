import * as types from './mutation_types';
import * as consts from './constants';
import * as rootTypes from '../../mutation_types';
import router from '../../../ide_router';
import service from '../../../services';
import flash from '../../../../flash';
import { stripHtml } from '../../../../lib/utils/text_utility';
import editor from '../../../lib/editor';

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
    .catch(() => flash('Error checking branch data. Please try again.', 'alert', document, null, false, true));

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

  commit(rootTypes.SET_BRANCH_WORKING_REFERENCE, {
    projectId: rootState.currentProjectId,
    branchId: rootState.currentBranchId,
    reference: data.id,
  }, { root: true });

  const cachedEditorModels = editor.editorInstance.modelManager.models;

  rootState.changedFiles.forEach((entry) => {
    const editorModel = cachedEditorModels.get(entry.path);

    commit(rootTypes.SET_LAST_COMMIT_DATA, {
      entry,
      lastCommit,
    }, { root: true });

    commit(rootTypes.SET_FILE_RAW_DATA, {
      file: entry,
      raw: entry.content,
    }, { root: true });

    editorModel.originalModel.setValue(entry.raw);
    editorModel.model.setValue(entry.raw);
  });

  commit(rootTypes.REMOVE_ALL_CHANGES_FILES, null, { root: true });

  if (state.commitAction === consts.COMMIT_TO_NEW_BRANCH) {
    const fileUrl = rootGetters.activeFile.url.replace(rootState.currentBranchId, branch);

    router.push(`/project${fileUrl}`);
  }

  window.scrollTo(0, 0);

  dispatch('updateCommitAction', consts.COMMIT_TO_CURRENT_BRANCH);
};

export const commitChanges = ({ commit, state, getters, dispatch, rootState }) => {
  const newBranch = state.commitAction !== consts.COMMIT_TO_CURRENT_BRANCH;
  const payload = {
    branch: getters.branchName,
    commit_message: state.commitMessage,
    actions: rootState.changedFiles.map(f => ({
      action: f.tempFile ? 'create' : 'update',
      file_path: f.path,
      content: f.content,
      encoding: f.base64 ? 'base64' : 'text',
    })),
    start_branch: newBranch ? rootState.currentBranchId : undefined,
  };
  const getCommitStatus = newBranch ? Promise.resolve(false) : dispatch('checkCommitStatus');

  commit(types.UPDATE_LOADING, true);

  getCommitStatus.then(branchChanged => new Promise((resolve) => {
    if (branchChanged) {
      // show the modal with a Bootstrap call
      $('#ide-create-branch-modal').modal('show');
    } else {
      resolve();
    }
  }))
  .then(() => service.commit(rootState.currentProjectId, payload))
  .then(({ data }) => {
    const { branch } = payload;

    commit(types.UPDATE_LOADING, false);

    if (!data.short_id) {
      flash(data.message, 'alert', document, null, false, true);
      return;
    }

    let commitMsg = `Your changes have been committed. Commit ${data.short_id}`;

    if (data.stats) {
      commitMsg += ` with ${data.stats.additions} additions, ${data.stats.deletions} deletions.`;
    }

    commit(rootTypes.SET_LAST_COMMIT_MSG, commitMsg, { root: true });

    if (state.commitAction === consts.COMMIT_TO_NEW_BRANCH_MR) {
      const selectedProject = rootState.projects[rootState.currentProjectId];

      dispatch(
        'redirectToUrl',
        `${selectedProject.web_url}/merge_requests/new?merge_request[source_branch]=${branch}&merge_request[target_branch]=${rootState.currentBranchId}`,
        { root: true },
      );
    } else {
      dispatch('updateFilesAfterCommit', { data, branch });
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
