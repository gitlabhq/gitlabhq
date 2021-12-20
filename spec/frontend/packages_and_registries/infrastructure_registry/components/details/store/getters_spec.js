import { packagePipeline } from '~/packages_and_registries/infrastructure_registry/details/store/getters';
import {
  npmPackage,
  mockPipelineInfo,
  mavenPackage as packageWithoutBuildInfo,
} from '../../mock_data';

describe('Getters PackageDetails Store', () => {
  let state;

  const defaultState = {
    packageEntity: packageWithoutBuildInfo,
  };

  const setupState = (testState = {}) => {
    state = {
      ...defaultState,
      ...testState,
    };
  };

  describe('packagePipeline', () => {
    it('should return the pipeline info when pipeline exists', () => {
      setupState({
        packageEntity: {
          ...npmPackage,
          pipeline: mockPipelineInfo,
        },
      });

      expect(packagePipeline(state)).toEqual(mockPipelineInfo);
    });

    it('should return null when build_info does not exist', () => {
      setupState({ pipeline: undefined });

      expect(packagePipeline(state)).toBe(null);
    });
  });
});
