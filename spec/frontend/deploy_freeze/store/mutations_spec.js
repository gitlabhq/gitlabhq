import * as types from '~/deploy_freeze/store/mutation_types';
import mutations from '~/deploy_freeze/store/mutations';
import state from '~/deploy_freeze/store/state';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { formatTimezone } from '~/lib/utils/datetime_utility';
import { freezePeriodsFixture } from '../helpers';
import {
  timezoneDataFixture,
  findTzByName,
} from '../../vue_shared/components/timezone_dropdown/helpers';

describe('Deploy freeze mutations', () => {
  let stateCopy;

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
      const timezoneNames = {
        'Europe/Berlin': '[UTC+2] Berlin',
        'Etc/UTC': '[UTC 0] UTC',
        'America/New_York': '[UTC-4] Eastern Time (US & Canada)',
      };

      mutations[types.RECEIVE_FREEZE_PERIODS_SUCCESS](stateCopy, freezePeriodsFixture);

      const expectedFreezePeriods = freezePeriodsFixture.map((freezePeriod) => ({
        ...convertObjectPropsToCamelCase(freezePeriod),
        cronTimezone: {
          formattedTimezone: timezoneNames[freezePeriod.cron_timezone],
          identifier: freezePeriod.cron_timezone,
        },
      }));

      expect(stateCopy.freezePeriods).toMatchObject(expectedFreezePeriods);
    });
  });

  describe('SET_SELECTED_TIMEZONE', () => {
    it('should set the cron timezone', () => {
      const selectedTz = findTzByName('Pacific Time (US & Canada)');
      const timezone = {
        formattedTimezone: formatTimezone(selectedTz),
        identifier: selectedTz.identifier,
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

  describe('SET_FREEZE_END_CRON', () => {
    it('should set freezeEndCron', () => {
      mutations[types.SET_FREEZE_END_CRON](stateCopy, '5 0 * 8 *');

      expect(stateCopy.freezeEndCron).toBe('5 0 * 8 *');
    });
  });

  describe('SET_SELECTED_ID', () => {
    it('should set selectedId', () => {
      mutations[types.SET_SELECTED_ID](stateCopy, 5);

      expect(stateCopy.selectedId).toBe(5);
    });
  });

  describe('REQUEST_DELETE_FREEZE_PERIOD', () => {
    beforeEach(() => {
      stateCopy = state({
        freezePeriods: [{ id: 1 }],
      });
    });

    it('should set freeze period', () => {
      mutations[types.REQUEST_DELETE_FREEZE_PERIOD](stateCopy, 1);
      expect(stateCopy.freezePeriods[0].isDeleting).toBe(true);
    });
  });
});
