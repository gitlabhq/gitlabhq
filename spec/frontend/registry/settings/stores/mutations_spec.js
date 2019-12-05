import mutations from '~/registry/settings/stores/mutations';
import * as types from '~/registry/settings/stores/mutation_types';
import createState from '~/registry/settings/stores/state';

describe('Mutations Registry Store', () => {
  let mockState;

  beforeEach(() => {
    mockState = createState();
  });

  describe('SET_INITIAL_STATE', () => {
    it('should set the initial state', () => {
      const payload = { helpPagePath: 'foo', registrySettingsEndpoint: 'bar' };
      const expectedState = { ...mockState, ...payload };
      mutations[types.SET_INITIAL_STATE](mockState, payload);

      expect(mockState.endpoint).toEqual(expectedState.endpoint);
    });
  });
});
