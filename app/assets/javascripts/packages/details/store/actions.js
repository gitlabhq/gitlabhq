import Api from '~/api';
import createFlash from '~/flash';
import { FETCH_PACKAGE_VERSIONS_ERROR } from '../constants';
import * as types from './mutation_types';

export default ({ commit, state }) => {
  commit(types.SET_LOADING, true);

  const { project_id, id } = state.packageEntity;

  return Api.projectPackage(project_id, id)
    .then(({ data }) => {
      if (data.versions) {
        commit(types.SET_PACKAGE_VERSIONS, data.versions.reverse());
      }
    })
    .catch(() => {
      createFlash(FETCH_PACKAGE_VERSIONS_ERROR);
    })
    .finally(() => {
      commit(types.SET_LOADING, false);
    });
};
