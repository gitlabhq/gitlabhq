import Api from '~/api';
import createFlash from '~/flash';
import {
  DELETE_PACKAGE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
} from '~/packages/shared/constants';
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
      createFlash({ message: FETCH_PACKAGE_VERSIONS_ERROR, type: 'warning' });
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
    createFlash({ message: DELETE_PACKAGE_ERROR_MESSAGE, type: 'warning' });
  });
};

export const deletePackageFile = (
  {
    state: {
      packageEntity: { project_id, id },
      packageFiles,
    },
    commit,
  },
  fileId,
) => {
  return Api.deleteProjectPackageFile(project_id, id, fileId)
    .then(() => {
      const filtered = packageFiles.filter((f) => f.id !== fileId);
      commit(types.UPDATE_PACKAGE_FILES, filtered);
      createFlash({ message: DELETE_PACKAGE_FILE_SUCCESS_MESSAGE, type: 'success' });
    })
    .catch(() => {
      createFlash({ message: DELETE_PACKAGE_FILE_ERROR_MESSAGE, type: 'warning' });
    });
};
