import createFlash from '~/flash';
import { __ } from '~/locale';

import * as mutationTypes from './mutation_types';
import loadSourceContent from '~/static_site_editor/services/load_source_content';
import submitContentChanges from '~/static_site_editor/services/submit_content_changes';

export const loadContent = ({ commit, state: { sourcePath, projectId } }) => {
  commit(mutationTypes.LOAD_CONTENT);

  return loadSourceContent({ sourcePath, projectId })
    .then(data => commit(mutationTypes.RECEIVE_CONTENT_SUCCESS, data))
    .catch(() => {
      commit(mutationTypes.RECEIVE_CONTENT_ERROR);
      createFlash(__('An error ocurred while loading your content. Please try again.'));
    });
};

export const setContent = ({ commit }, content) => {
  commit(mutationTypes.SET_CONTENT, content);
};

export const submitChanges = ({ state: { projectId, content, sourcePath, username }, commit }) => {
  commit(mutationTypes.SUBMIT_CHANGES);

  return submitContentChanges({ content, projectId, sourcePath, username })
    .then(data => commit(mutationTypes.SUBMIT_CHANGES_SUCCESS, data))
    .catch(error => {
      commit(mutationTypes.SUBMIT_CHANGES_ERROR, error.message);
    });
};

export const dismissSubmitChangesError = ({ commit }) => {
  commit(mutationTypes.DISMISS_SUBMIT_CHANGES_ERROR);
};

export default () => {};
