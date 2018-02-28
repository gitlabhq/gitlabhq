import * as types from './mutation_types';
import {
  parseIntPagination,
  normalizeHeaders,
  convertPermissionToBoolean,
} from '../../../lib/utils/common_utils';

export default {
  /**
   * Because it's used in several different routes the endpoint may vary:
   *  1. In the new merge request view the endpoint won't include `.json`
   *  1. In the MR view, Commits view and Pipelines view it will include `.json`
   */
  [types.SET_ENDPOINT](state, endpoint) {
    let parsedEndpoint;

    if (endpoint.indexOf('.json') === -1) {
      parsedEndpoint = `${endpoint}.json`;
    } else {
      parsedEndpoint = endpoint;
    }

    Object.assign(state, { endpoint: parsedEndpoint });
  },

  [types.SET_PERMISSIONS](state, dataset) {
    Object.assign(state, {
      canCreatePipeline: convertPermissionToBoolean(dataset.canCreatePipeline),
      canResetCache: dataset.resetCachePath !== null || dataset.resetCachePath !== undefined,
    });
  },

  [types.SET_PATHS](state, dataset) {
    Object.assign(state, {
      helpPagePath: dataset.helpPagePath,
      autoDevopsHelpPath: dataset.autoDevopsHelpPath,
      newPipelinePath: dataset.newPipelinePath,
      ciLintPath: dataset.ciLintPath,
      resetCachePath: dataset.resetCachePath,
      emptyStateSvgPath: dataset.emptyStateSvgPath,
      errorStateSvgPath: dataset.errorStateSvgPath,
    });
  },

  [types.SET_VIEW_TYPE](state, viewType) {
    Object.assign(state, { viewType });
  },

  [types.SET_HAS_CI](state, value) {
    Object.assign(state, { hasCI: value });
  },

  [types.SHOW_LOADING](state) {
    Object.assign(state, { isLoading: true });
  },

  [types.HIDE_LOADING](state) {
    Object.assign(state, { isLoading: false });
  },

  [types.SET_HAS_ERROR](state, value) {
    Object.assign(state, { hasError: value });
  },

  [types.SET_IS_MAKING_REQUEST](state, value) {
    Object.assign(state, { isMakingRequest: value });
  },

  [types.SET_HAS_MADE_REQUEST](state, value) {
    Object.assign(state, { hasMadeRequest: value });
  },

  [types.SET_SHOULD_UPDATE_GRAPH_DROPDOWN](state, value) {
    Object.assign(state, { updateGraphDropdown: value });
  },

  [types.SET_SCOPE](state, value) {
    Object.assign(state, { scope: value });
  },

  [types.SET_PAGE](state, value) {
    Object.assign(state, { page: value });
  },

  [types.SET_REQUEST_DATA](state, value) {
    Object.assign(state, { requestData: value });
  },

  [types.SET_PIPELINES](state, pipelines) {
    Object.assign(state, { pipelines });
  },

  [types.SET_PAGINATION](state, pagination) {
    const parsedPagination = parseIntPagination(normalizeHeaders(pagination));

    Object.assign(state, { pagination: parsedPagination });
  },

  [types.SET_COUNT](state, pipelines) {
    Object.assign(state, { pipelines });
  },
};
