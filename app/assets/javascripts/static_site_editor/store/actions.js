import createFlash from '~/flash';
import { __ } from '~/locale';

import * as mutationTypes from './mutation_types';
import loadSourceContent from '~/static_site_editor/services/load_source_content';

export const loadContent = ({ commit, state: { sourcePath, projectId } }) => {
  commit(mutationTypes.LOAD_CONTENT);

  return loadSourceContent({ sourcePath, projectId })
    .then(data => commit(mutationTypes.RECEIVE_CONTENT_SUCCESS, data))
    .catch(() => {
      commit(mutationTypes.RECEIVE_CONTENT_ERROR);
      createFlash(__('An error ocurred while loading your content. Please try again.'));
    });
};

export default () => {};
