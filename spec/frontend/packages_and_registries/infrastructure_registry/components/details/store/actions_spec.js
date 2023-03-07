import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import { createAlert, VARIANT_SUCCESS, VARIANT_WARNING } from '~/alert';
import { FETCH_PACKAGE_VERSIONS_ERROR } from '~/packages_and_registries/infrastructure_registry/details/constants';
import {
  fetchPackageVersions,
  deletePackage,
  deletePackageFile,
} from '~/packages_and_registries/infrastructure_registry/details/store/actions';
import * as types from '~/packages_and_registries/infrastructure_registry/details/store/mutation_types';
import {
  DELETE_PACKAGE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
} from '~/packages_and_registries/shared/constants';
import { npmPackage as packageEntity } from '../../mock_data';

jest.mock('~/alert');
jest.mock('~/api.js');

describe('Actions Package details store', () => {
  describe('fetchPackageVersions', () => {
    it('should fetch the package versions', async () => {
      Api.projectPackage = jest.fn().mockResolvedValue({ data: packageEntity });

      await testAction(
        fetchPackageVersions,
        undefined,
        { packageEntity },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_PACKAGE_VERSIONS, payload: packageEntity.versions },
          { type: types.SET_LOADING, payload: false },
        ],
        [],
      );
      expect(Api.projectPackage).toHaveBeenCalledWith(packageEntity.project_id, packageEntity.id);
    });

    it("does not set the versions if they don't exist", async () => {
      Api.projectPackage = jest.fn().mockResolvedValue({ data: { packageEntity, versions: null } });

      await testAction(
        fetchPackageVersions,
        undefined,
        { packageEntity },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
        ],
        [],
      );
      expect(Api.projectPackage).toHaveBeenCalledWith(packageEntity.project_id, packageEntity.id);
    });

    it('should create alert on API error', async () => {
      Api.projectPackage = jest.fn().mockRejectedValue();

      await testAction(
        fetchPackageVersions,
        undefined,
        { packageEntity },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
        ],
        [],
      );
      expect(Api.projectPackage).toHaveBeenCalledWith(packageEntity.project_id, packageEntity.id);
      expect(createAlert).toHaveBeenCalledWith({
        message: FETCH_PACKAGE_VERSIONS_ERROR,
        variant: VARIANT_WARNING,
      });
    });
  });

  describe('deletePackage', () => {
    it('should call Api.deleteProjectPackage', async () => {
      Api.deleteProjectPackage = jest.fn().mockResolvedValue();
      await testAction(deletePackage, undefined, { packageEntity }, [], []);
      expect(Api.deleteProjectPackage).toHaveBeenCalledWith(
        packageEntity.project_id,
        packageEntity.id,
      );
    });
    it('should create alert on API error', async () => {
      Api.deleteProjectPackage = jest.fn().mockRejectedValue();

      await testAction(deletePackage, undefined, { packageEntity }, [], []);
      expect(createAlert).toHaveBeenCalledWith({
        message: DELETE_PACKAGE_ERROR_MESSAGE,
        variant: VARIANT_WARNING,
      });
    });
  });

  describe('deletePackageFile', () => {
    const fileId = 'a_file_id';

    it('should call Api.deleteProjectPackageFile and commit the right data', async () => {
      const packageFiles = [{ id: 'foo' }, { id: fileId }];
      Api.deleteProjectPackageFile = jest.fn().mockResolvedValue();
      await testAction(
        deletePackageFile,
        fileId,
        { packageEntity, packageFiles },
        [{ type: types.UPDATE_PACKAGE_FILES, payload: [{ id: 'foo' }] }],
        [],
      );
      expect(Api.deleteProjectPackageFile).toHaveBeenCalledWith(
        packageEntity.project_id,
        packageEntity.id,
        fileId,
      );
      expect(createAlert).toHaveBeenCalledWith({
        message: DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
        variant: VARIANT_SUCCESS,
      });
    });

    it('should create alert on API error', async () => {
      Api.deleteProjectPackageFile = jest.fn().mockRejectedValue();
      await testAction(deletePackageFile, fileId, { packageEntity }, [], []);
      expect(createAlert).toHaveBeenCalledWith({
        message: DELETE_PACKAGE_FILE_ERROR_MESSAGE,
        variant: VARIANT_WARNING,
      });
    });
  });
});
