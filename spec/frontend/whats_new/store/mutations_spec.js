import mutations from '~/whats_new/store/mutations';
import createState from '~/whats_new/store/state';
import * as types from '~/whats_new/store/mutation_types';

describe('whats new mutations', () => {
  let state;

  beforeEach(() => {
    state = createState;
  });

  describe('openDrawer', () => {
    it('sets open to true', () => {
      mutations[types.OPEN_DRAWER](state);
      expect(state.open).toBe(true);
    });
  });

  describe('closeDrawer', () => {
    it('sets open to false', () => {
      mutations[types.CLOSE_DRAWER](state);
      expect(state.open).toBe(false);
    });
  });

  describe('setFeatures', () => {
    it('sets features to data', () => {
      mutations[types.SET_FEATURES](state, 'bells and whistles');
      expect(state.features).toBe('bells and whistles');
    });
  });
});
