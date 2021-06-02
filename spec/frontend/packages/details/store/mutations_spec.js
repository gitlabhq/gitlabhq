import * as types from '~/packages/details/store/mutation_types';
import mutations from '~/packages/details/store/mutations';
import { npmPackage as packageEntity } from '../../mock_data';

describe('Mutations package details Store', () => {
  let mockState;

  beforeEach(() => {
    mockState = {
      packageEntity,
    };
  });

  describe('SET_LOADING', () => {
    it('should set loading', () => {
      mutations[types.SET_LOADING](mockState, true);

      expect(mockState.isLoading).toEqual(true);
    });
  });

  describe('SET_PACKAGE_VERSIONS', () => {
    it('should set the package entity versions', () => {
      const fakeVersions = [1, 2, 3];

      mutations[types.SET_PACKAGE_VERSIONS](mockState, fakeVersions);

      expect(mockState.packageEntity.versions).toEqual(fakeVersions);
    });
  });
  describe('UPDATE_PACKAGE_FILES', () => {
    it('should update the packageFiles', () => {
      const files = [1, 2, 3];

      mutations[types.UPDATE_PACKAGE_FILES](mockState, files);

      expect(mockState.packageFiles).toEqual(files);
    });
  });
});
