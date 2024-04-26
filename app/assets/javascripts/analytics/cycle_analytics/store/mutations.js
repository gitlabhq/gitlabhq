import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { formatMedianValues } from '../utils';
import { PAGINATION_SORT_DIRECTION_DESC, PAGINATION_SORT_FIELD_DURATION } from '../constants';
import * as types from './mutation_types';

export default {
  [types.INITIALIZE_VSA](
    state,
    { groupPath, features, createdBefore, createdAfter, pagination = {}, namespace = {} },
  ) {
    state.groupPath = groupPath;
    state.namespace = namespace;
    state.createdBefore = createdBefore;
    state.createdAfter = createdAfter;
    state.features = features;

    state.pagination = {
      page: pagination.page ?? state.pagination.page,
      sort: pagination.sort ?? state.pagination.sort,
      direction: pagination.direction ?? state.pagination.direction,
    };
  },
  [types.SET_LOADING](state, loadingState) {
    state.isLoading = loadingState;
  },
  [types.SET_SELECTED_VALUE_STREAM](state, selectedValueStream = {}) {
    state.selectedValueStream = convertObjectPropsToCamelCase(selectedValueStream, { deep: true });
  },
  [types.SET_SELECTED_STAGE](state, stage) {
    state.selectedStage = stage;
  },
  [types.SET_DATE_RANGE](state, { createdAfter, createdBefore }) {
    state.createdBefore = createdBefore;
    state.createdAfter = createdAfter;
  },
  [types.SET_PREDEFINED_DATE_RANGE](state, predefinedDateRange) {
    state.predefinedDateRange = predefinedDateRange;
  },
  [types.SET_PAGINATION](state, { page, hasNextPage, sort, direction }) {
    state.pagination = {
      page,
      hasNextPage,
      sort: sort || PAGINATION_SORT_FIELD_DURATION,
      direction: direction || PAGINATION_SORT_DIRECTION_DESC,
    };
  },
  [types.SET_NO_ACCESS_ERROR](state) {
    state.hasNoAccessError = true;
  },
  [types.REQUEST_VALUE_STREAMS](state) {
    state.valueStreams = [];
  },
  [types.RECEIVE_VALUE_STREAMS_SUCCESS](state, valueStreams = []) {
    state.valueStreams = valueStreams;
  },
  [types.RECEIVE_VALUE_STREAMS_ERROR](state) {
    state.valueStreams = [];
  },
  [types.REQUEST_VALUE_STREAM_STAGES](state) {
    state.stages = [];
  },
  [types.RECEIVE_VALUE_STREAM_STAGES_SUCCESS](state, { stages = [] }) {
    state.stages = stages.map((s) => convertObjectPropsToCamelCase(s, { deep: true }));
  },
  [types.RECEIVE_VALUE_STREAM_STAGES_ERROR](state) {
    state.stages = [];
  },
  [types.REQUEST_STAGE_DATA](state) {
    state.isLoadingStage = true;
    state.isEmptyStage = false;
    state.selectedStageEvents = [];

    state.hasNoAccessError = false;
  },
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, events = []) {
    state.isLoadingStage = false;
    state.isEmptyStage = !events.length;
    state.selectedStageEvents = events.map((ev) =>
      convertObjectPropsToCamelCase(ev, { deep: true }),
    );

    state.hasNoAccessError = false;
  },
  [types.RECEIVE_STAGE_DATA_ERROR](state, error) {
    state.isLoadingStage = false;
    state.isEmptyStage = true;
    state.selectedStageEvents = [];

    state.selectedStageError = error;
  },
  [types.REQUEST_STAGE_MEDIANS](state) {
    state.medians = {};
  },
  [types.RECEIVE_STAGE_MEDIANS_SUCCESS](state, medians) {
    state.medians = formatMedianValues(medians);
  },
  [types.RECEIVE_STAGE_MEDIANS_ERROR](state) {
    state.medians = {};
  },
  [types.REQUEST_STAGE_COUNTS](state) {
    state.stageCounts = {};
  },
  [types.RECEIVE_STAGE_COUNTS_SUCCESS](state, stageCounts = []) {
    state.stageCounts = stageCounts.reduce(
      (acc, { id, count }) => ({
        ...acc,
        [id]: count,
      }),
      {},
    );
  },
  [types.RECEIVE_STAGE_COUNTS_ERROR](state) {
    state.stageCounts = {};
  },
};
