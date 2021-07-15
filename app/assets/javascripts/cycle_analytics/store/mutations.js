import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { DEFAULT_DAYS_TO_DISPLAY } from '../constants';
import {
  decorateData,
  decorateEvents,
  formatMedianValues,
  calculateFormattedDayInPast,
} from '../utils';
import * as types from './mutation_types';

export default {
  [types.INITIALIZE_VSA](state, { requestPath, fullPath, groupPath, projectId, features }) {
    state.requestPath = requestPath;
    state.fullPath = fullPath;
    state.groupPath = groupPath;
    state.id = projectId;
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
  [types.SET_DATE_RANGE](state, { startDate }) {
    state.startDate = startDate;
    const { now, past } = calculateFormattedDayInPast(startDate);
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
    state.stages = stages.map((s) => ({
      ...convertObjectPropsToCamelCase(s, { deep: true }),
      // NOTE: we set the component type here to match the current behaviour
      // this can be removed when we migrate to the update stage table
      // https://gitlab.com/gitlab-org/gitlab/-/issues/326704
      component: `stage-${s.id}-component`,
    }));
  },
  [types.RECEIVE_VALUE_STREAM_STAGES_ERROR](state) {
    state.stages = [];
  },
  [types.REQUEST_CYCLE_ANALYTICS_DATA](state) {
    state.isLoading = true;
    state.hasError = false;
    if (!state.features.cycleAnalyticsForGroups) {
      state.medians = {};
    }
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, data) {
    const { summary, medians } = decorateData(data);
    if (!state.features.cycleAnalyticsForGroups) {
      state.medians = formatMedianValues(medians);
    }
    state.permissions = data.permissions;
    state.summary = summary;
    state.hasError = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR](state) {
    state.isLoading = false;
    state.hasError = true;
    if (!state.features.cycleAnalyticsForGroups) {
      state.medians = {};
    }
  },
  [types.REQUEST_STAGE_DATA](state) {
    state.isLoadingStage = true;
    state.isEmptyStage = false;
    state.selectedStageEvents = [];
    state.hasError = false;
  },
  [types.RECEIVE_STAGE_DATA_SUCCESS](state, { events = [] }) {
    const { selectedStage } = state;
    state.isLoadingStage = false;
    state.isEmptyStage = !events.length;
    state.selectedStageEvents = decorateEvents(events, selectedStage);
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
};
