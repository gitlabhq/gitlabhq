import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { formatTimezone } from '~/lib/utils/datetime_utility';
import * as types from './mutation_types';

const formatTimezoneName = (freezePeriod, timezoneList) => {
  const tz = timezoneList.find((timezone) => timezone.identifier === freezePeriod.cron_timezone);
  return convertObjectPropsToCamelCase({
    ...freezePeriod,
    cron_timezone: {
      formattedTimezone: tz && formatTimezone(tz),
      identifier: freezePeriod.cron_timezone,
    },
  });
};

const setFreezePeriodIsDeleting = (state, id, isDeleting) => {
  const freezePeriod = state.freezePeriods.find((f) => f.id === id);

  if (!freezePeriod) {
    return;
  }

  freezePeriod.isDeleting = isDeleting;
};

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

  [types.REQUEST_DELETE_FREEZE_PERIOD](state, id) {
    setFreezePeriodIsDeleting(state, id, true);
  },

  [types.RECEIVE_DELETE_FREEZE_PERIOD_SUCCESS](state, id) {
    state.freezePeriods = state.freezePeriods.filter((f) => f.id !== id);
  },

  [types.RECEIVE_DELETE_FREEZE_PERIOD_ERROR](state, id) {
    setFreezePeriodIsDeleting(state, id, false);
  },

  [types.RESET_MODAL](state) {
    state.freezeStartCron = '';
    state.freezeEndCron = '';
    state.selectedTimezone = '';
    state.selectedTimezoneIdentifier = '';
    state.selectedId = '';
  },
};
