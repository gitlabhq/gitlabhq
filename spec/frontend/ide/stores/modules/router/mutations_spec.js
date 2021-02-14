import * as types from '~/ide/stores/modules/router/mutation_types';
import mutations from '~/ide/stores/modules/router/mutations';
import createState from '~/ide/stores/modules/router/state';

const TEST_PATH = 'test/path/abc';

describe('ide/stores/modules/router/mutations', () => {
  let state;

  beforeEach(() => {
    state = createState();
  });

  describe(types.PUSH, () => {
    it('updates state', () => {
      expect(state.fullPath).toBe('');

      mutations[types.PUSH](state, TEST_PATH);

      expect(state.fullPath).toBe(TEST_PATH);
    });
  });
});
