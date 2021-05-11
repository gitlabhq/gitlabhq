import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import * as types from './mutation_types';

const formatTimezoneName = (freezePeriod, timezoneList) =>
  convertObjectPropsToCamelCase({
    ...freezePeriod,
    cron_timezone: {
      formattedTimezone: timezoneList.find((tz) => tz.identifier === freezePeriod.cron_timezone)
        ?.name,
      identifier: freezePeriod.cron_timezone,
    },
  });

export default {
  [types.REQUEST_FREEZE_PERIODS](state) {
    state.isLoading = true;
  },

  [types.RECEIVE_FREEZE_PERIODS_SUCCESS](state, freezePeriods) {
    state.isLoading = false;
    state.freezePeriods = freezePeriods.map((freezePeriod) =>
      formatTimezoneName(freezePeriod, state.timezoneData),
    );
  },

  [types.REQUEST_ADD_FREEZE_PERIOD](state) {
    state.isLoading = true;
  },

  [types.RECEIVE_ADD_FREEZE_PERIOD_SUCCESS](state) {
    state.isLoading = false;
  },

  [types.RECEIVE_ADD_FREEZE_PERIOD_ERROR](state, error) {
    state.isLoading = false;
    state.error = error;
  },

  [types.SET_SELECTED_TIMEZONE](state, timezone) {
    state.selectedTimezone = timezone.formattedTimezone;
    state.selectedTimezoneIdentifier = timezone.identifier;
  },

  [types.SET_FREEZE_START_CRON](state, freezeStartCron) {
    state.freezeStartCron = freezeStartCron;
  },

  [types.SET_FREEZE_END_CRON](state, freezeEndCron) {
    state.freezeEndCron = freezeEndCron;
  },

  [types.SET_SELECTED_ID](state, id) {
    state.selectedId = id;
  },

  [types.RESET_MODAL](state) {
    state.freezeStartCron = '';
    state.freezeEndCron = '';
    state.selectedTimezone = '';
    state.selectedTimezoneIdentifier = '';
    state.selectedId = '';
  },
};
