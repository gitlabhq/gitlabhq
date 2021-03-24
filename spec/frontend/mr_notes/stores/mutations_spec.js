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

  describe(mutationTypes.SET_MR_METADATA, () => {
    it('store the provided MR Metadata in the state', () => {
      const state = {};
      const metadata = { propA: 'A', propB: 'B' };

      mutations[mutationTypes.SET_MR_METADATA](state, metadata);

      expect(state.mrMetadata.propA).toBe('A');
      expect(state.mrMetadata.propB).toBe('B');
    });
  });
});
