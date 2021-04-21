import { decorateData, decorateEvents } from '../utils';
import * as types from './mutation_types';

export default {
  [types.INITIALIZE_VSA](state, { requestPath }) {
    state.requestPath = requestPath;
  },
  [types.SET_SELECTED_STAGE](state, stage) {
    state.isLoadingStage = true;
    state.selectedStage = stage;
    state.isLoadingStage = false;
  },
  [types.SET_DATE_RANGE](state, { startDate }) {
    state.startDate = startDate;
  },
  [types.REQUEST_CYCLE_ANALYTICS_DATA](state) {
    state.isLoading = true;
    state.stages = [];
    state.hasError = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_SUCCESS](state, data) {
    state.isLoading = false;
    const { stages, summary } = decorateData(data);
    state.stages = stages;
    state.summary = summary;
    state.hasError = false;
  },
  [types.RECEIVE_CYCLE_ANALYTICS_DATA_ERROR](state) {
    state.isLoading = false;
    state.stages = [];
    state.hasError = true;
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
  [types.RECEIVE_STAGE_DATA_ERROR](state) {
    state.isLoadingStage = false;
    state.isEmptyStage = true;
    state.selectedStageEvents = [];
    state.hasError = true;
  },
};
