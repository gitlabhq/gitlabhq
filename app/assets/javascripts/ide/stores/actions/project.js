import service from '../../services';
import * as types from '../mutation_types';
import { pushState } from '../utils';

export const getProjectData = (
  { commit, state, dispatch },
  { namespace, projectId } = {},
) => {
  // commit(types.TOGGLE_LOADING, tree);
  debugger;

  service.getProjectData(namespace, projectId)
    .then((res) => {
      /*const pageTitle = decodeURI(normalizeHeaders(res.headers)['PAGE-TITLE']);

      setPageTitle(pageTitle);*/
      debugger;

      return res.json();
    })
    .then((data) => {
      /* const prevLastCommitPath = tree.lastCommitPath;
      if (!state.isInitialRoot) {
        commit(types.SET_ROOT, data.path === '/');
      }

      dispatch('updateDirectoryData', { data, tree });
      commit(types.SET_PARENT_TREE_URL, data.parent_tree_url);
      commit(types.SET_LAST_COMMIT_URL, { tree, url: data.last_commit_path });
      commit(types.TOGGLE_LOADING, tree);

      if (prevLastCommitPath !== null) {
        dispatch('getLastCommitData', tree);
      }

      pushState(endpoint); */

      console.log('DATA :  ',data);
    })
    .catch(() => {
      flash('Error loading project data. Please try again.');
      //commit(types.TOGGLE_LOADING, tree);
    });
};
