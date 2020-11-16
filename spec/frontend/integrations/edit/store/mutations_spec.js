import mutations from '~/integrations/edit/store/mutations';
import createState from '~/integrations/edit/store/state';
import * as types from '~/integrations/edit/store/mutation_types';

describe('Integration form store mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(`${types.SET_OVERRIDE}`, () => {
    it('sets override', () => {
      mutations[types.SET_OVERRIDE](state, true);

      expect(state.override).toBe(true);
    });
  });

  describe(`${types.SET_IS_SAVING}`, () => {
    it('sets isSaving', () => {
      mutations[types.SET_IS_SAVING](state, true);

      expect(state.isSaving).toBe(true);
    });
  });

  describe(`${types.SET_IS_TESTING}`, () => {
    it('sets isTesting', () => {
      mutations[types.SET_IS_TESTING](state, true);

      expect(state.isTesting).toBe(true);
    });
  });

  describe(`${types.SET_IS_RESETTING}`, () => {
    it('sets isResetting', () => {
      mutations[types.SET_IS_RESETTING](state, true);

      expect(state.isResetting).toBe(true);
    });
  });
});
