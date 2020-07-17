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
});
