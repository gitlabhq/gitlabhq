import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { __ } from '~/locale';
import { DEFAULT_DAYS_TO_DISPLAY } from '../constants';
import * as types from './mutation_types';

export const fetchCycleAnalyticsData = ({
  state: { requestPath, startDate },
  dispatch,
  commit,
}) => {
  commit(types.REQUEST_CYCLE_ANALYTICS_DATA);

  return axios
    .get(requestPath, {
      params: { 'cycle_analytics[start_date]': startDate },
    })
    .then(({ data }) => commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS, data))
    .then(() => dispatch('setSelectedStage'))
    .then(() => dispatch('fetchStageData'))
    .catch(() => {
      commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR);
      createFlash({
        message: __('There was an error while fetching value stream analytics data.'),
      });
    });
};

export const fetchStageData = ({ state: { requestPath, selectedStage, startDate }, commit }) => {
  commit(types.REQUEST_STAGE_DATA);

  return axios
    .get(`${requestPath}/events/${selectedStage.name}.json`, {
      params: { 'cycle_analytics[start_date]': startDate },
    })
    .then(({ data }) => commit(types.RECEIVE_STAGE_DATA_SUCCESS, data))
    .catch(() => commit(types.RECEIVE_STAGE_DATA_ERROR));
};

export const setSelectedStage = ({ commit, state: { stages } }, selectedStage = null) => {
  const stage = selectedStage || stages[0];
  commit(types.SET_SELECTED_STAGE, stage);
};

export const setDateRange = ({ commit }, { startDate = DEFAULT_DAYS_TO_DISPLAY }) =>
  commit(types.SET_DATE_RANGE, { startDate });

export const initializeVsa = ({ commit, dispatch }, initialData = {}) => {
  commit(types.INITIALIZE_VSA, initialData);
  return dispatch('fetchCycleAnalyticsData');
};
