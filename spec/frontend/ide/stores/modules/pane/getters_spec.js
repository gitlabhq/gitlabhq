import * as getters from '~/ide/stores/modules/pane/getters';
import state from '~/ide/stores/modules/pane/state';

describe('IDE pane module getters', () => {
  const TEST_VIEW = 'test-view';
  const TEST_KEEP_ALIVE_VIEWS = {
    [TEST_VIEW]: true,
  };

  describe('isAliveView', () => {
    it('returns true if given view is in keepAliveViews', () => {
      const result = getters.isAliveView({ keepAliveViews: TEST_KEEP_ALIVE_VIEWS }, {})(TEST_VIEW);

      expect(result).toBe(true);
    });

    it('returns true if given view is active view and open', () => {
      const result = getters.isAliveView({ ...state(), isOpen: true, currentView: TEST_VIEW })(
        TEST_VIEW,
      );

      expect(result).toBe(true);
    });

    it('returns false if given view is active view and closed', () => {
      const result = getters.isAliveView({ ...state(), currentView: TEST_VIEW })(TEST_VIEW);

      expect(result).toBe(false);
    });

    it('returns false if given view is not activeView', () => {
      const result = getters.isAliveView({
        ...state(),
        isOpen: true,
        currentView: `${TEST_VIEW}_other`,
      })(TEST_VIEW);

      expect(result).toBe(false);
    });
  });
});
