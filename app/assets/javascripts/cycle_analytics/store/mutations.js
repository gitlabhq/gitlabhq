import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { DEFAULT_DAYS_TO_DISPLAY } from '../constants';
import { formatMedianValues, calculateFormattedDayInPast } from '../utils';
import * as types from './mutation_types';

export default {
  [types.INITIALIZE_VSA](state, { endpoints, features }) {
    state.endpoints = endpoints;
    const { now, past } = calculateFormattedDayInPast(DEFAULT_DAYS_TO_DISPLAY);
    state.createdBefore = now;
    state.createdAfter = past;
    state.features = features;
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
  [types.SET_DATE_RANGE](state, daysInPast) {
    state.daysInPast = daysInPast;
    const { now, past } = calculateFormattedDayInPast(daysInPast);
    state.createdBefore = now;
    state.createdAfter = past;
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
  [types.REQUEST_CYCLE_ANALYTICS_DATA](state) {
    state.isLoading = true;
    state.hasError = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, data) {
    state.permissions = data?.permissions || {};
    state.hasError = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
  },
  [types.REQUEST_STAGE_DATA](state) {
    state.isLoadingStage = true;
    state.isEmptyStage = false;
    state.selectedStageEvents = [];
    state.hasError = false;
  },
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, events = []) {
    state.isLoadingStage = false;
    state.isEmptyStage = !events.length;
    state.selectedStageEvents = events.map((ev) =>
      convertObjectPropsToCamelCase(ev, { deep: true }),
    );
    state.hasError = false;
  },
  [types.RECEIVE_STAGE_DATA_ERROR](state, error) {
    state.isLoadingStage = false;
    state.isEmptyStage = true;
    state.selectedStageEvents = [];
    state.hasError = true;
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
