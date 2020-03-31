// import store from '~/monitoring/stores/embed_group';
import * as actions from '~/monitoring/stores/embed_group/actions';
import * as types from '~/monitoring/stores/embed_group/mutation_types';
import { mockNamespace } from '../../mock_data';

describe('Embed group actions', () => {
  describe('addModule', () => {
    it('adds a module to the store', () => {
      const commit = jest.fn();

      actions.addModule({ commit }, mockNamespace);

      expect(commit).toHaveBeenCalledWith(types.ADD_MODULE, mockNamespace);
    });
  });
});
