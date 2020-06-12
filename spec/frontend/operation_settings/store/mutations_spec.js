import mutations from '~/operation_settings/store/mutations';
import createState from '~/operation_settings/store/state';
import { timezones } from '~/monitoring/format_date';

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

  describe('SET_DASHBOARD_TIMEZONE', () => {
    it('sets dashboardTimezoneSetting', () => {
      mutations.SET_DASHBOARD_TIMEZONE(localState, timezones.LOCAL);

      expect(localState.dashboardTimezone.selected).not.toBeUndefined();
      expect(localState.dashboardTimezone.selected).toBe(timezones.LOCAL);
    });
  });
});
