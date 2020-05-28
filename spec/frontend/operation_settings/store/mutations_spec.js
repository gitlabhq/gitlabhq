import mutations from '~/operation_settings/store/mutations';
import createState from '~/operation_settings/store/state';

describe('operation settings mutations', () => {
  let localState;

  beforeEach(() => {
    localState = createState();
  });

  describe('SET_EXTERNAL_DASHBOARD_URL', () => {
    it('sets externalDashboardUrl', () => {
      const mockUrl = 'mockUrl';
      mutations.SET_EXTERNAL_DASHBOARD_URL(localState, mockUrl);

      expect(localState.externalDashboard.url).toBe(mockUrl);
    });
  });
});
