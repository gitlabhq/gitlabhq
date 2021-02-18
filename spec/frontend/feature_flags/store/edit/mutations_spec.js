import * as types from '~/feature_flags/store/edit/mutation_types';
import mutations from '~/feature_flags/store/edit/mutations';
import state from '~/feature_flags/store/edit/state';

describe('Feature flags Edit Module Mutations', () => {
  let stateCopy;

  beforeEach(() => {
    stateCopy = state({ endpoint: 'feature_flags.json', path: '/feature_flags' });
  });

  describe('REQUEST_FEATURE_FLAG', () => {
    it('should set isLoading to true', () => {
      mutations[types.REQUEST_FEATURE_FLAG](stateCopy);

      expect(stateCopy.isLoading).toEqual(true);
    });

    it('should set error to an empty array', () => {
      mutations[types.REQUEST_FEATURE_FLAG](stateCopy);

      expect(stateCopy.error).toEqual([]);
    });
  });

  describe('RECEIVE_FEATURE_FLAG_SUCCESS', () => {
    const data = {
      name: '*',
      description: 'All environments',
      scopes: [{ id: 1 }],
      iid: 5,
      version: 'new_version_flag',
      strategies: [
        { id: 1, scopes: [{ environment_scope: '*' }], name: 'default', parameters: {} },
      ],
    };

    beforeEach(() => {
      mutations[types.RECEIVE_FEATURE_FLAG_SUCCESS](stateCopy, data);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to false', () => {
      expect(stateCopy.hasError).toEqual(false);
    });

    it('should set name with the provided one', () => {
      expect(stateCopy.name).toEqual(data.name);
    });

    it('should set description with the provided one', () => {
      expect(stateCopy.description).toEqual(data.description);
    });

    it('should set scope with the provided one', () => {
      expect(stateCopy.scope).toEqual(data.scope);
    });

    it('should set the iid to the provided one', () => {
      expect(stateCopy.iid).toEqual(data.iid);
    });

    it('should set the version to the provided one', () => {
      expect(stateCopy.version).toBe('new_version_flag');
    });

    it('should set the strategies to the provided one', () => {
      expect(stateCopy.strategies).toEqual([
        {
          id: 1,
          scopes: [{ environmentScope: '*', shouldBeDestroyed: false }],
          name: 'default',
          parameters: {},
          shouldBeDestroyed: false,
        },
      ]);
    });
  });

  describe('RECEIVE_FEATURE_FLAG_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_FEATURE_FLAG_ERROR](stateCopy);
    });

    it('should set isLoading to false', () => {
      expect(stateCopy.isLoading).toEqual(false);
    });

    it('should set hasError to true', () => {
      expect(stateCopy.hasError).toEqual(true);
    });
  });

  describe('REQUEST_UPDATE_FEATURE_FLAG', () => {
    beforeEach(() => {
      mutations[types.REQUEST_UPDATE_FEATURE_FLAG](stateCopy);
    });

    it('should set isSendingRequest to true', () => {
      expect(stateCopy.isSendingRequest).toEqual(true);
    });

    it('should set error to an empty array', () => {
      expect(stateCopy.error).toEqual([]);
    });
  });

  describe('RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS', () => {
    it('should set isSendingRequest to false', () => {
      mutations[types.RECEIVE_UPDATE_FEATURE_FLAG_SUCCESS](stateCopy);

      expect(stateCopy.isSendingRequest).toEqual(false);
    });
  });

  describe('RECEIVE_UPDATE_FEATURE_FLAG_ERROR', () => {
    beforeEach(() => {
      mutations[types.RECEIVE_UPDATE_FEATURE_FLAG_ERROR](stateCopy, {
        message: ['Name is required'],
      });
    });

    it('should set isSendingRequest to false', () => {
      expect(stateCopy.isSendingRequest).toEqual(false);
    });

    it('should set error to the given message', () => {
      expect(stateCopy.error).toEqual(['Name is required']);
    });
  });
});
