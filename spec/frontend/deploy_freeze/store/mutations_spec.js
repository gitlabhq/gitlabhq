import state from '~/deploy_freeze/store/state';
import mutations from '~/deploy_freeze/store/mutations';
import * as types from '~/deploy_freeze/store/mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

describe('Deploy freeze mutations', () => {
  let stateCopy;
  const timezoneDataFixture = getJSONFixture('/api/freeze-periods/timezone_data.json');

  beforeEach(() => {
    stateCopy = state({
      projectId: '8',
      timezoneData: timezoneDataFixture,
    });
  });

  describe('RESET_MODAL', () => {
    it('should reset modal state', () => {
      mutations[types.RESET_MODAL](stateCopy);

      expect(stateCopy.freezeStartCron).toBe('');
      expect(stateCopy.freezeEndCron).toBe('');
      expect(stateCopy.selectedTimezone).toBe('');
      expect(stateCopy.selectedTimezoneIdentifier).toBe('');
    });
  });

  describe('RECEIVE_FREEZE_PERIODS_SUCCESS', () => {
    it('should set freeze periods and format timezones from identifiers to names', () => {
      const timezoneNames = ['Berlin', 'UTC', 'Eastern Time (US & Canada)'];
      const freezePeriodsFixture = getJSONFixture('/api/freeze-periods/freeze_periods.json');

      mutations[types.RECEIVE_FREEZE_PERIODS_SUCCESS](stateCopy, freezePeriodsFixture);

      const expectedFreezePeriods = freezePeriodsFixture.map((freezePeriod, index) => ({
        ...convertObjectPropsToCamelCase(freezePeriod),
        cronTimezone: timezoneNames[index],
      }));

      expect(stateCopy.freezePeriods).toMatchObject(expectedFreezePeriods);
    });
  });

  describe('SET_SELECTED_TIMEZONE', () => {
    it('should set the cron timezone', () => {
      const timezone = {
        formattedTimezone: '[UTC -7] Pacific Time (US & Canada)',
        identifier: 'America/Los_Angeles',
      };
      mutations[types.SET_SELECTED_TIMEZONE](stateCopy, timezone);

      expect(stateCopy.selectedTimezone).toEqual(timezone.formattedTimezone);
      expect(stateCopy.selectedTimezoneIdentifier).toEqual(timezone.identifier);
    });
  });

  describe('SET_FREEZE_START_CRON', () => {
    it('should set freezeStartCron', () => {
      mutations[types.SET_FREEZE_START_CRON](stateCopy, '5 0 * 8 *');

      expect(stateCopy.freezeStartCron).toBe('5 0 * 8 *');
    });
  });

  describe('SET_FREEZE_ENDT_CRON', () => {
    it('should set freezeEndCron', () => {
      mutations[types.SET_FREEZE_END_CRON](stateCopy, '5 0 * 8 *');

      expect(stateCopy.freezeEndCron).toBe('5 0 * 8 *');
    });
  });
});
