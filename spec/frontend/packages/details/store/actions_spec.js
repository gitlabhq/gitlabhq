import testAction from 'helpers/vuex_action_helper';
import Api from '~/api';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { FETCH_PACKAGE_VERSIONS_ERROR } from '~/packages/details/constants';
import { fetchPackageVersions, deletePackage } from '~/packages/details/store/actions';
import * as types from '~/packages/details/store/mutation_types';
import { DELETE_PACKAGE_ERROR_MESSAGE } from '~/packages/shared/constants';
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
          expect(createFlash).toHaveBeenCalledWith(FETCH_PACKAGE_VERSIONS_ERROR);
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
        expect(createFlash).toHaveBeenCalledWith(DELETE_PACKAGE_ERROR_MESSAGE);
        done();
      });
    });
  });
});
