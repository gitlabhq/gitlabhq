import * as types from './mutation_types';

export default {
  [types.REQUEST_FREEZE_PERIODS](state) {
    state.isLoading = true;
  },

  [types.RECEIVE_FREEZE_PERIODS_SUCCESS](state, freezePeriods) {
    state.isLoading = false;
    state.freezePeriods = freezePeriods;
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

  [types.RESET_MODAL](state) {
    state.freezeStartCron = '';
    state.freezeEndCron = '';
    state.selectedTimezone = '';
    state.selectedTimezoneIdentifier = '';
  },
};
