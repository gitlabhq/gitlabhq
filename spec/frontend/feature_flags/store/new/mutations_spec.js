import state from '~/feature_flags/store/modules/new/state';
import mutations from '~/feature_flags/store/modules/new/mutations';
import * as types from '~/feature_flags/store/modules/new/mutation_types';

describe('Feature flags New Module Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state();
  });

  describe('SET_ENDPOINT', () => {
    it('should set endpoint', () => {
      mutations[types.SET_ENDPOINT](stateCopy, 'feature_flags.json');

      expect(stateCopy.endpoint).toEqual('feature_flags.json');
    });
  });

  describe('SET_PATH', () => {
    it('should set provided options', () => {
      mutations[types.SET_PATH](stateCopy, 'feature_flags');

      expect(stateCopy.path).toEqual('feature_flags');
    });
  });

  describe('REQUEST_CREATE_FEATURE_FLAG', () => {
    it('should set isSendingRequest to true', () => {
      mutations[types.REQUEST_CREATE_FEATURE_FLAG](stateCopy);

      expect(stateCopy.isSendingRequest).toEqual(true);
    });

    it('should set error to an empty array', () => {
      mutations[types.REQUEST_CREATE_FEATURE_FLAG](stateCopy);

      expect(stateCopy.error).toEqual([]);
    });
  });

  describe('RECEIVE_CREATE_FEATURE_FLAG_SUCCESS', () => {
    it('should set isSendingRequest to false', () => {
      mutations[types.RECEIVE_CREATE_FEATURE_FLAG_SUCCESS](stateCopy);

      expect(stateCopy.isSendingRequest).toEqual(false);
    });
  });

  describe('RECEIVE_CREATE_FEATURE_FLAG_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_CREATE_FEATURE_FLAG_ERROR](stateCopy, {
        message: ['Name is required'],
      });
    });

    it('should set isSendingRequest to false', () => {
      expect(stateCopy.isSendingRequest).toEqual(false);
    });

    it('should set hasError to true', () => {
      expect(stateCopy.error).toEqual(['Name is required']);
    });
  });
});
