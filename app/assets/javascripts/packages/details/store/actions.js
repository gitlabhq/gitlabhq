import Api from '~/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { DELETE_PACKAGE_ERROR_MESSAGE } from '~/packages/shared/constants';
import { FETCH_PACKAGE_VERSIONS_ERROR } from '../constants';
import * as types from './mutation_types';

export const fetchPackageVersions = ({ commit, state }) => {
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

export const deletePackage = ({
  state: {
    packageEntity: { project_id, id },
  },
}) => {
  return Api.deleteProjectPackage(project_id, id).catch(() => {
    createFlash(DELETE_PACKAGE_ERROR_MESSAGE);
  });
};
