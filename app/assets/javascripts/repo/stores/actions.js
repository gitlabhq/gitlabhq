import flash from '../../flash';
import service from '../services';
import * as types from './mutation_types';
import * as getters from './getters';
import { visitUrl } from '../../lib/utils/url_utility';

export const redirectToUrl = url => visitUrl(url);

export const setInitialData = ({ commit }, data) => commit(types.SET_INITIAL_DATA, data);

export const closeDiscardPopup = ({ commit }) => commit(types.TOGGLE_DISCARD_POPUP, false);

export const discardAllChanges = ({ commit, state }) => {
  const changedFiles = getters.changedFiles(state);

  changedFiles.forEach(file => commit(types.DISCARD_FILE_CHANGES, file));
};

export const closeAllFiles = ({ state, dispatch }) => {
  state.openFiles.forEach(file => dispatch('closeFile', file));
};

export const toggleEditMode = ({ commit, state, dispatch }, force = false) => {
  const changedFiles = getters.changedFiles(state);

  if (changedFiles.length && !force) {
    commit(types.TOGGLE_DISCARD_POPUP, true);
  } else {
    commit(types.TOGGLE_EDIT_MODE);
    commit(types.TOGGLE_DISCARD_POPUP, false);
    dispatch('toggleBlobView');
    dispatch('discardAllChanges');
  }
};

export const toggleBlobView = ({ commit, state }) => {
  if (state.editMode) {
    commit(types.SET_EDIT_MODE);
  } else {
    commit(types.SET_PREVIEW_MODE);
  }
};

export const checkCommitStatus = ({ state }) => service.getBranchData(
  state.project.id,
  state.currentBranch,
)
  .then((data) => {
    const { id } = data.commit;

    if (state.currentRef !== id) {
      return true;
    }

    return false;
  })
  .catch(() => flash('Error checking branch data. Please try again.'));

export const commitChanges = ({ commit, state, dispatch }, { payload, newMr }) =>
  service.commit(state.project.id, payload)
  .then((data) => {
    if (!data.short_id) {
      flash(data.message);
      return;
    }

    flash(`Your changes have been committed. Commit ${data.short_id} with ${data.stats.additions} additions, ${data.stats.deletions} deletions.`, 'notice');

    if (newMr) {
      redirectToUrl(`${state.endpoints.newMergeRequestUrl}${payload.branch}`);
    } else {
      // TODO: push a new state with the branch name
      commit(types.SET_COMMIT_REF, data.id);
      dispatch('discardAllChanges');
      dispatch('closeAllFiles');
      dispatch('toggleEditMode');
    }
  })
  .catch(() => flash('Error committing changes. Please try again.'));

export const popHistoryState = ({ state, dispatch }) => {
  const treeList = getters.treeList(state);
  const tree = treeList.find(file => file.url === state.previousUrl);

  if (!tree) return;

  if (tree.type === 'tree') {
    dispatch('toggleTreeOpen', { endpoint: tree.url, tree });
  }
};

export * from './actions/tree';
export * from './actions/file';
export * from './actions/branch';
