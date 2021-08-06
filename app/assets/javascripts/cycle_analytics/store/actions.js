import {
  getProjectValueStreamStages,
  getProjectValueStreams,
  getProjectValueStreamMetrics,
  getValueStreamStageMedian,
  getValueStreamStageRecords,
  getValueStreamStageCounts,
} from '~/api/analytics_api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { DEFAULT_VALUE_STREAM, I18N_VSA_ERROR_STAGE_MEDIAN } from '../constants';
import * as types from './mutation_types';

export const setSelectedValueStream = ({ commit, dispatch }, valueStream) => {
  commit(types.SET_SELECTED_VALUE_STREAM, valueStream);
  return Promise.all([dispatch('fetchValueStreamStages'), dispatch('fetchCycleAnalyticsData')]);
};

export const fetchValueStreamStages = ({ commit, state }) => {
  const {
    endpoints: { fullPath },
    selectedValueStream: { id },
  } = state;
  commit(types.REQUEST_VALUE_STREAM_STAGES);

  return getProjectValueStreamStages(fullPath, id)
    .then(({ data }) => commit(types.RECEIVE_VALUE_STREAM_STAGES_SUCCESS, data))
    .catch(({ response: { status } }) => {
      commit(types.RECEIVE_VALUE_STREAM_STAGES_ERROR, status);
    });
};

export const receiveValueStreamsSuccess = ({ commit, dispatch }, data = []) => {
  commit(types.RECEIVE_VALUE_STREAMS_SUCCESS, data);
  if (data.length) {
    const [firstStream] = data;
    return dispatch('setSelectedValueStream', firstStream);
  }
  return dispatch('setSelectedValueStream', DEFAULT_VALUE_STREAM);
};

export const fetchValueStreams = ({ commit, dispatch, state }) => {
  const {
    endpoints: { fullPath },
  } = state;
  commit(types.REQUEST_VALUE_STREAMS);

  const stageRequests = ['setSelectedStage', 'fetchStageMedians', 'fetchStageCountValues'];
  return getProjectValueStreams(fullPath)
    .then(({ data }) => dispatch('receiveValueStreamsSuccess', data))
    .then(() => Promise.all(stageRequests.map((r) => dispatch(r))))
    .catch(({ response: { status } }) => {
      commit(types.RECEIVE_VALUE_STREAMS_ERROR, status);
    });
};
export const fetchCycleAnalyticsData = ({
  state: {
    endpoints: { requestPath },
  },
  getters: { legacyFilterParams },
  commit,
}) => {
  commit(types.REQUEST_CYCLE_ANALYTICS_DATA);

  return getProjectValueStreamMetrics(requestPath, legacyFilterParams)
    .then(({ data }) => commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS, data))
    .catch(() => {
      commit(types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR);
      createFlash({
        message: __('There was an error while fetching value stream summary data.'),
      });
    });
};

export const fetchStageData = ({ getters: { requestParams, filterParams }, commit }) => {
  commit(types.REQUEST_STAGE_DATA);

  return getValueStreamStageRecords(requestParams, filterParams)
    .then(({ data }) => {
      // when there's a query timeout, the request succeeds but the error is encoded in the response data
      if (data?.error) {
        commit(types.RECEIVE_STAGE_DATA_ERROR, data.error);
      } else {
        commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);
      }
    })
    .catch(() => commit(types.RECEIVE_STAGE_DATA_ERROR));
};

const getStageMedians = ({ stageId, vsaParams, filterParams = {} }) => {
  return getValueStreamStageMedian({ ...vsaParams, stageId }, filterParams).then(({ data }) => ({
    id: stageId,
    value: data?.value || null,
  }));
};

export const fetchStageMedians = ({
  state: { stages },
  getters: { requestParams: vsaParams, filterParams },
  commit,
}) => {
  commit(types.REQUEST_STAGE_MEDIANS);
  return Promise.all(
    stages.map(({ id: stageId }) =>
      getStageMedians({
        vsaParams,
        stageId,
        filterParams,
      }),
    ),
  )
    .then((data) => commit(types.RECEIVE_STAGE_MEDIANS_SUCCESS, data))
    .catch((error) => {
      commit(types.RECEIVE_STAGE_MEDIANS_ERROR, error);
      createFlash({ message: I18N_VSA_ERROR_STAGE_MEDIAN });
    });
};

const getStageCounts = ({ stageId, vsaParams, filterParams = {} }) => {
  return getValueStreamStageCounts({ ...vsaParams, stageId }, filterParams).then(({ data }) => ({
    id: stageId,
    ...data,
  }));
};

export const fetchStageCountValues = ({
  state: { stages },
  getters: { requestParams: vsaParams, filterParams },
  commit,
}) => {
  commit(types.REQUEST_STAGE_COUNTS);
  return Promise.all(
    stages.map(({ id: stageId }) =>
      getStageCounts({
        vsaParams,
        stageId,
        filterParams,
      }),
    ),
  )
    .then((data) => commit(types.RECEIVE_STAGE_COUNTS_SUCCESS, data))
    .catch((error) => {
      commit(types.RECEIVE_STAGE_COUNTS_ERROR, error);
      createFlash({
        message: __('There was an error fetching stage total counts'),
      });
    });
};

export const setSelectedStage = ({ dispatch, commit, state: { stages } }, selectedStage = null) => {
  const stage = selectedStage || stages[0];
  commit(types.SET_SELECTED_STAGE, stage);
  return dispatch('fetchStageData');
};

export const setLoading = ({ commit }, value) => commit(types.SET_LOADING, value);

const refetchStageData = (dispatch) => {
  return Promise.resolve()
    .then(() => dispatch('setLoading', true))
    .then(() =>
      Promise.all([
        dispatch('fetchCycleAnalyticsData'),
        dispatch('fetchStageData'),
        dispatch('fetchStageMedians'),
      ]),
    )
    .finally(() => dispatch('setLoading', false));
};

export const setFilters = ({ dispatch }) => refetchStageData(dispatch);

export const setDateRange = ({ dispatch, commit }, daysInPast) => {
  commit(types.SET_DATE_RANGE, daysInPast);
  return refetchStageData(dispatch);
};

export const initializeVsa = ({ commit, dispatch }, initialData = {}) => {
  commit(types.INITIALIZE_VSA, initialData);

  return dispatch('setLoading', true)
    .then(() => dispatch('fetchValueStreams'))
    .finally(() => dispatch('setLoading', false));
};
