import {
  getProjectValueStreamStages,
  getProjectValueStreams,
  getValueStreamStageMedian,
  getValueStreamStageRecords,
  getValueStreamStageCounts,
} from '~/api/analytics_api';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import {
  DEFAULT_VALUE_STREAM,
  I18N_VSA_ERROR_STAGE_MEDIAN,
  LABELS_ENDPOINT,
  MILESTONES_ENDPOINT,
} from '../constants';
import { constructPathWithNamespace } from '../utils';
import * as types from './mutation_types';

export const setSelectedValueStream = ({ commit, dispatch }, valueStream) => {
  commit(types.SET_SELECTED_VALUE_STREAM, valueStream);
  return dispatch('fetchValueStreamStages');
};

export const fetchValueStreamStages = ({ commit, state }) => {
  const {
    namespace: { restApiRequestPath },
    selectedValueStream: { id },
  } = state;
  commit(types.REQUEST_VALUE_STREAM_STAGES);

  return getProjectValueStreamStages(restApiRequestPath, id)
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
    namespace: { restApiRequestPath },
  } = state;
  commit(types.REQUEST_VALUE_STREAMS);

  return getProjectValueStreams(restApiRequestPath)
    .then(({ data }) => dispatch('receiveValueStreamsSuccess', data))
    .catch(({ response: { status } }) => {
      commit(types.RECEIVE_VALUE_STREAMS_ERROR, status);
    });
};

export const fetchStageData = ({
  getters: { requestParams, filterParams, paginationParams },
  commit,
}) => {
  commit(types.REQUEST_STAGE_DATA);

  return getValueStreamStageRecords(requestParams, { ...filterParams, ...paginationParams })
    .then(({ data, headers }) => {
      // when there's a query timeout, the request succeeds but the error is encoded in the response data
      if (data?.error) {
        commit(types.RECEIVE_STAGE_DATA_ERROR, data.error);
      } else {
        commit(types.RECEIVE_STAGE_DATA_SUCCESS, data);
        const { page = null, nextPage = null } = parseIntPagination(normalizeHeaders(headers));
        commit(types.SET_PAGINATION, { ...paginationParams, page, hasNextPage: Boolean(nextPage) });
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
      createAlert({ message: I18N_VSA_ERROR_STAGE_MEDIAN });
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
      createAlert({
        message: __('There was an error fetching stage total counts'),
      });
    });
};

export const fetchValueStreamStageData = ({ dispatch }) =>
  Promise.all([
    dispatch('fetchStageData'),
    dispatch('fetchStageMedians'),
    dispatch('fetchStageCountValues'),
  ]);

export const refetchStageData = async ({ dispatch, commit }) => {
  commit(types.SET_LOADING, true);
  await dispatch('fetchValueStreamStageData');
  commit(types.SET_LOADING, false);
};

export const setSelectedStage = ({ dispatch, commit }, selectedStage = null) => {
  commit(types.SET_SELECTED_STAGE, selectedStage);
  return dispatch('refetchStageData');
};

export const setFilters = ({ dispatch }) => dispatch('refetchStageData');

export const setDateRange = ({ dispatch, commit }, { createdAfter, createdBefore }) => {
  commit(types.SET_DATE_RANGE, { createdAfter, createdBefore });
  return dispatch('refetchStageData');
};

export const setPredefinedDateRange = ({ commit }, predefinedDateRange) => {
  commit(types.SET_PREDEFINED_DATE_RANGE, predefinedDateRange);
};

export const setInitialStage = ({ dispatch, commit, state: { stages } }, stage) => {
  if (!stages.length && !stage) {
    commit(types.SET_NO_ACCESS_ERROR);
    return null;
  }

  const selectedStage = stage || stages[0];
  commit(types.SET_SELECTED_STAGE, selectedStage);
  return dispatch('fetchValueStreamStageData');
};

export const updateStageTablePagination = (
  { commit, dispatch, state: { selectedStage } },
  paginationParams,
) => {
  commit(types.SET_PAGINATION, paginationParams);
  return dispatch('fetchStageData', selectedStage.id);
};

export const initializeVsa = async ({ commit, dispatch }, initialData = {}) => {
  commit(types.INITIALIZE_VSA, initialData);

  const {
    groupPath,
    namespace,
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
    selectedStage = null,
  } = initialData;

  dispatch('filters/setEndpoints', {
    labelsEndpoint: constructPathWithNamespace(namespace, LABELS_ENDPOINT),
    milestonesEndpoint: constructPathWithNamespace(namespace, MILESTONES_ENDPOINT),
    groupEndpoint: groupPath,
    projectEndpoint: namespace.restApiRequestPath,
  });

  dispatch('filters/initialize', {
    selectedAuthor,
    selectedMilestone,
    selectedAssigneeList,
    selectedLabelList,
  });

  commit(types.SET_LOADING, true);
  await dispatch('fetchValueStreams');
  await dispatch('setInitialStage', selectedStage);
  commit(types.SET_LOADING, false);
};
