import * as types from '~/feature_flags/store/new/mutation_types';
import mutations from '~/feature_flags/store/new/mutations';
import state from '~/feature_flags/store/new/state';

describe('Feature flags New Module Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state({ endpoint: 'feature_flags.json', path: 'feature_flags' });
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
