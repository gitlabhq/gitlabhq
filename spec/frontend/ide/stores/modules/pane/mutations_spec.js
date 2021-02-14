import * as types from '~/ide/stores/modules/pane/mutation_types';
import mutations from '~/ide/stores/modules/pane/mutations';
import state from '~/ide/stores/modules/pane/state';

describe('IDE pane module mutations', () => {
  const TEST_VIEW = 'test-view';
  let mockedState;

  beforeEach(() => {
    mockedState = state();
  });

  describe('SET_OPEN', () => {
    it('sets isOpen', () => {
      mockedState.isOpen = false;

      mutations[types.SET_OPEN](mockedState, true);

      expect(mockedState.isOpen).toBe(true);
    });
  });

  describe('SET_CURRENT_VIEW', () => {
    it('sets currentView', () => {
      mockedState.currentView = null;

      mutations[types.SET_CURRENT_VIEW](mockedState, TEST_VIEW);

      expect(mockedState.currentView).toEqual(TEST_VIEW);
    });
  });

  describe('KEEP_ALIVE_VIEW', () => {
    it('adds entry to keepAliveViews', () => {
      mutations[types.KEEP_ALIVE_VIEW](mockedState, TEST_VIEW);

      expect(mockedState.keepAliveViews).toEqual({
        [TEST_VIEW]: true,
      });
    });
  });
});
