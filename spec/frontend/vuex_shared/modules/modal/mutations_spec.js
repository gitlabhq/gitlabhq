import * as types from '~/vuex_shared/modules/modal/mutation_types';
import mutations from '~/vuex_shared/modules/modal/mutations';

describe('Vuex ModalModule mutations', () => {
  describe(`${types.SHOW}`, () => {
    it('sets isVisible to true', () => {
      const state = {
        isVisible: false,
      };

      mutations[types.SHOW](state);

      expect(state).toEqual({
        isVisible: true,
      });
    });
  });

  describe(`${types.HIDE}`, () => {
    it('sets isVisible to false', () => {
      const state = {
        isVisible: true,
      };

      mutations[types.HIDE](state);

      expect(state).toEqual({
        isVisible: false,
      });
    });
  });

  describe(`${types.OPEN}`, () => {
    it('sets data and sets isVisible to true', () => {
      const data = { id: 7 };
      const state = {
        isVisible: false,
        data: null,
      };

      mutations[types.OPEN](state, data);

      expect(state).toEqual({
        isVisible: true,
        data,
      });
    });
  });
});
