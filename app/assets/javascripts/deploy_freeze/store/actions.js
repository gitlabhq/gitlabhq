import * as types from './mutation_types';
import Api from '~/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export const requestAddFreezePeriod = ({ commit }) => {
  commit(types.REQUEST_ADD_FREEZE_PERIOD);
};

export const receiveAddFreezePeriodSuccess = ({ commit }) => {
  commit(types.RECEIVE_ADD_FREEZE_PERIOD_SUCCESS);
};

export const receiveAddFreezePeriodError = ({ commit }, error) => {
  commit(types.RECEIVE_ADD_FREEZE_PERIOD_ERROR, error);
};

export const addFreezePeriod = ({ state, dispatch, commit }) => {
  dispatch('requestAddFreezePeriod');

  return Api.createFreezePeriod(state.projectId, {
    freeze_start: state.freezeStartCron,
    freeze_end: state.freezeEndCron,
    cron_timezone: state.selectedTimezoneIdentifier,
  })
    .then(() => {
      dispatch('receiveAddFreezePeriodSuccess');
      commit(types.RESET_MODAL);
      dispatch('fetchFreezePeriods');
    })
    .catch(error => {
      createFlash(__('Error: Unable to create deploy freeze'));
      dispatch('receiveAddFreezePeriodError', error);
    });
};

export const requestFreezePeriods = ({ commit }) => {
  commit(types.REQUEST_FREEZE_PERIODS);
};
export const receiveFreezePeriodsSuccess = ({ state, commit }, freezePeriods) => {
  const addTimezoneIdentifier = freezePeriod =>
    convertObjectPropsToCamelCase({
      ...freezePeriod,
      cron_timezone: state.timezoneData.find(tz => tz.identifier === freezePeriod.cron_timezone)
        ?.name,
    });

  commit(types.RECEIVE_FREEZE_PERIODS_SUCCESS, freezePeriods.map(addTimezoneIdentifier));
};

export const fetchFreezePeriods = ({ dispatch, state }) => {
  dispatch('requestFreezePeriods');

  return Api.freezePeriods(state.projectId)
    .then(({ data }) => {
      dispatch('receiveFreezePeriodsSuccess', convertObjectPropsToCamelCase(data));
    })
    .catch(() => {
      createFlash(__('There was an error fetching the deploy freezes.'));
    });
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
