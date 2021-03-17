import mutationTypes from '~/mr_notes/stores/mutation_types';
import mutations from '~/mr_notes/stores/mutations';

describe('MR Notes Mutations', () => {
  describe(mutationTypes.SET_ENDPOINTS, () => {
    it('should set the endpoints value', () => {
      const state = {};
      const endpoints = { endpointA: 'A', endpointB: 'B' };

      mutations[mutationTypes.SET_ENDPOINTS](state, endpoints);

      expect(state.endpoints).toEqual(endpoints);
    });
  });
});
