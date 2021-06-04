import Api from '~/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const requestFreezePeriod = ({ commit }) => {
  commit(types.REQUEST_ADD_FREEZE_PERIOD);
};

export const receiveFreezePeriodSuccess = ({ commit }) => {
  commit(types.RECEIVE_ADD_FREEZE_PERIOD_SUCCESS);
};

export const receiveFreezePeriodError = ({ commit }, error) => {
  commit(types.RECEIVE_ADD_FREEZE_PERIOD_ERROR, error);
};

const receiveFreezePeriod = (store, request) => {
  const { dispatch, commit } = store;
  dispatch('requestFreezePeriod');

  request(store)
    .then(() => {
      dispatch('receiveFreezePeriodSuccess');
      commit(types.RESET_MODAL);
      dispatch('fetchFreezePeriods');
    })
    .catch((error) => {
      createFlash({
        message: __('Error: Unable to create deploy freeze'),
      });
      dispatch('receiveFreezePeriodError', error);
    });
};

export const addFreezePeriod = (store) =>
  receiveFreezePeriod(store, ({ state }) =>
    Api.createFreezePeriod(state.projectId, {
      freeze_start: state.freezeStartCron,
      freeze_end: state.freezeEndCron,
      cron_timezone: state.selectedTimezoneIdentifier,
    }),
  );

export const updateFreezePeriod = (store) =>
  receiveFreezePeriod(store, ({ state }) =>
    Api.updateFreezePeriod(state.projectId, {
      id: state.selectedId,
      freeze_start: state.freezeStartCron,
      freeze_end: state.freezeEndCron,
      cron_timezone: state.selectedTimezoneIdentifier,
    }),
  );

export const fetchFreezePeriods = ({ commit, state }) => {
  commit(types.REQUEST_FREEZE_PERIODS);

  return Api.freezePeriods(state.projectId)
    .then(({ data }) => {
      commit(types.RECEIVE_FREEZE_PERIODS_SUCCESS, data);
    })
    .catch(() => {
      createFlash({
        message: __('There was an error fetching the deploy freezes.'),
      });
    });
};

export const setFreezePeriod = ({ commit }, freezePeriod) => {
  commit(types.SET_SELECTED_ID, freezePeriod.id);
  commit(types.SET_SELECTED_TIMEZONE, freezePeriod.cronTimezone);
  commit(types.SET_FREEZE_START_CRON, freezePeriod.freezeStart);
  commit(types.SET_FREEZE_END_CRON, freezePeriod.freezeEnd);
};

export const setSelectedTimezone = ({ commit }, timezone) => {
  commit(types.SET_SELECTED_TIMEZONE, timezone);
};

export const setFreezeStartCron = ({ commit }, { freezeStartCron }) => {
  commit(types.SET_FREEZE_START_CRON, freezeStartCron);
};

export const setFreezeEndCron = ({ commit }, { freezeEndCron }) => {
  commit(types.SET_FREEZE_END_CRON, freezeEndCron);
};

export const resetModal = ({ commit }) => {
  commit(types.RESET_MODAL);
};
