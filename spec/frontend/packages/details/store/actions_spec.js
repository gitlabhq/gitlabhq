import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import createFlash from '~/flash';
import { FETCH_PACKAGE_VERSIONS_ERROR } from '~/packages/details/constants';
import {
  fetchPackageVersions,
  deletePackage,
  deletePackageFile,
} from '~/packages/details/store/actions';
import * as types from '~/packages/details/store/mutation_types';
import {
  DELETE_PACKAGE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_ERROR_MESSAGE,
  DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
} from '~/packages/shared/constants';
import { npmPackage as packageEntity } from '../../mock_data';

jest.mock('~/flash.js');
jest.mock('~/api.js');

describe('Actions Package details store', () => {
  describe('fetchPackageVersions', () => {
    it('should fetch the package versions', (done) => {
      Api.projectPackage = jest.fn().mockResolvedValue({ data: packageEntity });

      testAction(
        fetchPackageVersions,
        undefined,
        { packageEntity },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_PACKAGE_VERSIONS, payload: packageEntity.versions },
          { type: types.SET_LOADING, payload: false },
        ],
        [],
        () => {
          expect(Api.projectPackage).toHaveBeenCalledWith(
            packageEntity.project_id,
            packageEntity.id,
          );
          done();
        },
      );
    });

    it("does not set the versions if they don't exist", (done) => {
      Api.projectPackage = jest.fn().mockResolvedValue({ data: { packageEntity, versions: null } });

      testAction(
        fetchPackageVersions,
        undefined,
        { packageEntity },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
        ],
        [],
        () => {
          expect(Api.projectPackage).toHaveBeenCalledWith(
            packageEntity.project_id,
            packageEntity.id,
          );
          done();
        },
      );
    });

    it('should create flash on API error', (done) => {
      Api.projectPackage = jest.fn().mockRejectedValue();

      testAction(
        fetchPackageVersions,
        undefined,
        { packageEntity },
        [
          { type: types.SET_LOADING, payload: true },
          { type: types.SET_LOADING, payload: false },
        ],
        [],
        () => {
          expect(Api.projectPackage).toHaveBeenCalledWith(
            packageEntity.project_id,
            packageEntity.id,
          );
          expect(createFlash).toHaveBeenCalledWith({
            message: FETCH_PACKAGE_VERSIONS_ERROR,
            type: 'warning',
          });
          done();
        },
      );
    });
  });

  describe('deletePackage', () => {
    it('should call Api.deleteProjectPackage', (done) => {
      Api.deleteProjectPackage = jest.fn().mockResolvedValue();
      testAction(deletePackage, undefined, { packageEntity }, [], [], () => {
        expect(Api.deleteProjectPackage).toHaveBeenCalledWith(
          packageEntity.project_id,
          packageEntity.id,
        );
        done();
      });
    });
    it('should create flash on API error', (done) => {
      Api.deleteProjectPackage = jest.fn().mockRejectedValue();

      testAction(deletePackage, undefined, { packageEntity }, [], [], () => {
        expect(createFlash).toHaveBeenCalledWith({
          message: DELETE_PACKAGE_ERROR_MESSAGE,
          type: 'warning',
        });
        done();
      });
    });
  });

  describe('deletePackageFile', () => {
    const fileId = 'a_file_id';

    it('should call Api.deleteProjectPackageFile and commit the right data', (done) => {
      const packageFiles = [{ id: 'foo' }, { id: fileId }];
      Api.deleteProjectPackageFile = jest.fn().mockResolvedValue();
      testAction(
        deletePackageFile,
        fileId,
        { packageEntity, packageFiles },
        [{ type: types.UPDATE_PACKAGE_FILES, payload: [{ id: 'foo' }] }],
        [],
        () => {
          expect(Api.deleteProjectPackageFile).toHaveBeenCalledWith(
            packageEntity.project_id,
            packageEntity.id,
            fileId,
          );
          expect(createFlash).toHaveBeenCalledWith({
            message: DELETE_PACKAGE_FILE_SUCCESS_MESSAGE,
            type: 'success',
          });
          done();
        },
      );
    });
    it('should create flash on API error', (done) => {
      Api.deleteProjectPackageFile = jest.fn().mockRejectedValue();
      testAction(deletePackageFile, fileId, { packageEntity }, [], [], () => {
        expect(createFlash).toHaveBeenCalledWith({
          message: DELETE_PACKAGE_FILE_ERROR_MESSAGE,
          type: 'warning',
        });
        done();
      });
    });
  });
});
