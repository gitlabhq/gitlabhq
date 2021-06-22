import * as types from '~/feature_flags/store/index/mutation_types';
import mutations from '~/feature_flags/store/index/mutations';
import state from '~/feature_flags/store/index/state';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { getRequestData, rotateData, featureFlag } from '../../mock_data';

describe('Feature flags store Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state({});
  });

  describe('SET_FEATURE_FLAGS_OPTIONS', () => {
    it('should set provided options', () => {
      mutations[types.SET_FEATURE_FLAGS_OPTIONS](stateCopy, { page: '1', scope: 'all' });

      expect(stateCopy.options).toEqual({ page: '1', scope: 'all' });
    });
  });
  describe('REQUEST_FEATURE_FLAGS', () => {
    it('should set isLoading to true', () => {
      mutations[types.REQUEST_FEATURE_FLAGS](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });
  });

  describe('RECEIVE_FEATURE_FLAGS_SUCCESS', () => {
    const headers = {
      'x-next-page': '2',
      'x-page': '1',
      'X-Per-Page': '2',
      'X-Prev-Page': '',
      'X-TOTAL': '37',
      'X-Total-Pages': '5',
    };

    beforeEach(() => {
      mutations[types.RECEIVE_FEATURE_FLAGS_SUCCESS](stateCopy, { data: getRequestData, headers });
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to false', () => {
      expect(stateCopy.hasError).toEqual(false);
    });

    it('should set count with the given data', () => {
      expect(stateCopy.count).toEqual(37);
    });

    it('should set pagination', () => {
      expect(stateCopy.pageInfo).toEqual(parseIntPagination(normalizeHeaders(headers)));
    });
  });

  describe('RECEIVE_FEATURE_FLAGS_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_FEATURE_FLAGS_ERROR](stateCopy);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to true', () => {
      expect(stateCopy.hasError).toEqual(true);
    });
  });

  describe('REQUEST_ROTATE_INSTANCE_ID', () => {
    beforeEach(() => {
      mutations[types.REQUEST_ROTATE_INSTANCE_ID](stateCopy);
    });

    it('should set isRotating to true', () => {
      expect(stateCopy.isRotating).toBe(true);
    });

    it('should set hasRotateError to false', () => {
      expect(stateCopy.hasRotateError).toBe(false);
    });
  });

  describe('RECEIVE_ROTATE_INSTANCE_ID_SUCCESS', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_ROTATE_INSTANCE_ID_SUCCESS](stateCopy, { data: rotateData });
    });

    it('should set the instance id to the received data', () => {
      expect(stateCopy.instanceId).toBe(rotateData.token);
    });

    it('should set isRotating to false', () => {
      expect(stateCopy.isRotating).toBe(false);
    });

    it('should set hasRotateError to false', () => {
      expect(stateCopy.hasRotateError).toBe(false);
    });
  });

  describe('RECEIVE_ROTATE_INSTANCE_ID_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_ROTATE_INSTANCE_ID_ERROR](stateCopy);
    });

    it('should set isRotating to false', () => {
      expect(stateCopy.isRotating).toBe(false);
    });

    it('should set hasRotateError to true', () => {
      expect(stateCopy.hasRotateError).toBe(true);
    });
  });

  describe('UPDATE_FEATURE_FLAG', () => {
    beforeEach(() => {
      stateCopy.featureFlags = getRequestData.feature_flags.map((flag) => ({
        ...flag,
      }));
      stateCopy.count = { featureFlags: 1, userLists: 0 };

      mutations[types.UPDATE_FEATURE_FLAG](stateCopy, {
        ...featureFlag,
        active: false,
      });
    });

    it('should update the flag with the matching ID', () => {
      expect(stateCopy.featureFlags).toEqual([
        {
          ...featureFlag,
          active: false,
        },
      ]);
    });
  });

  describe('RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS', () => {
    const runUpdate = (stateCount, flagState, featureFlagUpdateParams) => {
      stateCopy.featureFlags = getRequestData.feature_flags.map((flag) => ({
        ...flag,
        ...flagState,
      }));
      stateCopy.count = stateCount;

      mutations[types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS](stateCopy, {
        ...featureFlag,
        ...featureFlagUpdateParams,
      });
    };

    it('updates the flag with the matching ID', () => {
      runUpdate({ all: 1, enabled: 1, disabled: 0 }, { active: true }, { active: false });

      expect(stateCopy.featureFlags).toEqual([
        {
          ...featureFlag,
          active: false,
        },
      ]);
    });
  });

  describe('RECEIVE_UPDATE_FEATURE_FLAG_ERROR', () => {
    beforeEach(() => {
      stateCopy.featureFlags = getRequestData.feature_flags.map((flag) => ({
        ...flag,
      }));
      mutations[types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR](stateCopy, featureFlag.id);
    });

    it('should update the flag with the matching ID, toggling active', () => {
      expect(stateCopy.featureFlags).toEqual([
        {
          ...featureFlag,
          active: false,
        },
      ]);
    });
  });

  describe('RECEIVE_CLEAR_ALERT', () => {
    it('clears the alert', () => {
      stateCopy.alerts = ['a server error'];

      mutations[types.RECEIVE_CLEAR_ALERT](stateCopy, 0);

      expect(stateCopy.alerts).toEqual([]);
    });

    it('clears the alert at the specified index', () => {
      stateCopy.alerts = ['a server error', 'another error', 'final error'];

      mutations[types.RECEIVE_CLEAR_ALERT](stateCopy, 1);

      expect(stateCopy.alerts).toEqual(['a server error', 'final error']);
    });
  });
});
