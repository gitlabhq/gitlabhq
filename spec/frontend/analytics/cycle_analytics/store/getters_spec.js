import * as getters from '~/analytics/cycle_analytics/store/getters';

import {
  allowedStages,
  stageMedians,
  transformedProjectStagePathData,
  selectedStage,
  stageCounts,
  basePaginationResult,
  initialPaginationState,
} from '../mock_data';

describe('Value stream analytics getters', () => {
  let state = {};

  describe('pathNavigationData', () => {
    it('returns the transformed data', () => {
      state = { stages: allowedStages, medians: stageMedians, selectedStage, stageCounts };
      expect(getters.pathNavigationData(state)).toEqual(transformedProjectStagePathData);
    });
  });

  describe('paginationParams', () => {
    beforeEach(() => {
      state = { pagination: initialPaginationState };
    });

    it('returns the `pagination` type', () => {
      expect(getters.paginationParams(state)).toEqual(basePaginationResult);
    });

    it('returns the `sort` type', () => {
      expect(getters.paginationParams(state)).toEqual(basePaginationResult);
    });

    it('with page=10, sets the `page` property', () => {
      const page = 10;
      state = { pagination: { ...initialPaginationState, page } };
      expect(getters.paginationParams(state)).toEqual({ ...basePaginationResult, page });
    });
  });
});
