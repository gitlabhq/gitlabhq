import state from '~/monitoring/stores/embed_group/state';
import mutations from '~/monitoring/stores/embed_group/mutations';
import * as types from '~/monitoring/stores/embed_group/mutation_types';
import { mockNamespace } from '../../mock_data';

describe('Embed group mutations', () => {
  describe('ADD_MODULE', () => {
    it('should add a module', () => {
      const stateCopy = state();

      mutations[types.ADD_MODULE](stateCopy, mockNamespace);

      expect(stateCopy.modules).toEqual([mockNamespace]);
    });
  });
});
