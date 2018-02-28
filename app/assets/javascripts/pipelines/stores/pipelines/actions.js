import _ from 'underscore';
import axios from '../../../lib/utils/axios_utils';
import createFlash from '../../../flash';
import { __ } from '../../../locale';
import { parseQueryStringIntoObject } from '../../../lib/utils/common_utils';
import * as types from './mutation_types';

/**
 * SYNC ACTIONS - BASE DATA
 */

export const setEndpoint = ({ commit }, endpoint) => {
  commit(types.SET_ENDPOINT, endpoint);
};

export const setRailsData = ({ commit }, dataset) => {
  commit(types.SET_PATHS, dataset);
  commit(types.SET_PERMISSIONS, dataset);
};

/**
 * Both the store and the components are shared between two apps.
 * 1. Main app is rendered in /pipelines route
 * 2. Child App is rendered in the following pages:
 *  1. merge_requests/pipelines
 *  2. commits/pipelines
 *  3. new merge request/pipelines (create route)
 * @param {Object}
 * @param {String} type main || child
 */
export const setViewType = ({ commit }, type) => {
  commit(types.SET_VIEW_TYPE, type);
};

export const setHasCI = ({ commit }, value) => {
  commit(types.SET_HAS_CI, value);
};

/**
 * SYNC ACTIONS - DYNAMIC DATA
 */

/**
 * Commits a mutation to store the pipelines.
 * Detached to allow being shared between two applications:
 *  - Main Pipeline View
 *  - MR & Commits View
 * @param {Object}
 */
export const setPipelines = ({ commit }, pipelines) => {
  commit(types.SET_PIPELINES, pipelines);
};

/**
 * Commits a mutation to store the counts used in the tabs in the Main Pipelines view.
 * @param {Object}
 */
export const setCount = ({ commit }, count) => {
  commit(types.SET_COUNT, count);
};

/**
 * Commits a mutation to store the pagination used in the Main Pipelines view.
 * @param {Object}
 */
export const setPagination = ({ commit }, pagination = {}) => {
  commit(types.SET_PAGINATION, pagination);
};

export const showLoading = ({ commit }) => {
  commit(types.SHOW_LOADING);
};

export const hideLoading = ({ commit }) => {
  commit(types.HIDE_LOADING);
};

export const toggleError = ({ commit }, value) => {
  commit(types.SET_HAS_ERROR, value);
};

export const toggleIsMakingRequest = ({ commit }, value) => {
  commit(types.SET_IS_MAKING_REQUEST, value);
};

export const toggleHasMadeRequest = ({ commit }, value) => {
  commit(types.SET_HAS_MADE_REQUEST, value);
};

export const toggleShouldUpdateGraphDropdown = ({ commit }, value) => {
  commit(types.SET_SHOULD_UPDATE_GRAPH_DROPDOWN, value);
};

/**
 * Used to handle state between pagination, tabs and URL
 *
 * @param {Object}
 * @param {String} scope
 */
export const setScope = ({ commit }, scope) => {
  commit(types.SET_SCOPE, scope);
};

/**
 * Used to handle state between pagination, tabs and URL
 *
 * @param {Object}
 * @param {String} page
 */
export const setPage = ({ commit }, page) => {
  commit(types.SET_SCOPE, page);
};

/**
 * Used to update the polling class with the correct state
 * between pagination, tabs and URL
 *
 * @param {Object}
 * @param {Object} requestData
 */
export const setRequestData = ({ commit }, requestData) => {
  commit(types.SET_REQUEST_DATA, requestData);
};

/**
 * ASYNC ACTIONS
 */

 /*
**
* axios callbacks are detached from the main action to allow to work with the polling function.
* Actions will be dispacted in the polling callback.
*
* Actions that set data are divided to allow the usage in two different apps.
* They should be the same in the future once the MR and Commits pipelines table allow pagination.
*/

/**
* Fetched the given endpoint and parameters.
* Used in polling method and in the refresh pipelines method.
*
* @returns {Promise}
*/
export const getPipelines = ({ state }) => axios
 .get(state.endpoint, { scope: state.scope, page: state.page });

/**
* Commits mutations for the common data shared between two applications:
*  - Main Pipeline View
*  - MR & Commits View
* @param {Object}
*/
export const successCallback = ({ dispatch, commit, state }, response) => {
  dispatch('hideLoading');
  dispatch('shouldUpdateGraphDropdown', true);
  dispatch('toggleHasMadeRequest', true);

  if (state.type === 'main') {
    if (_.isEqual(parseQueryStringIntoObject(response.url.split('?')[1]), state.requestData)) {
      dispatch('setPagination', response.headers);
      dispatch('setCount', response.data.count);
      commit(types.SET_PIPELINES, response.data.pipelines);
    }
  } else if (state.type === 'child') {
    // depending of the endpoint the response can either bring a `pipelines` key or not.
    const pipelines = response.data.pipelines || response.data;
    commit(types.SET_PIPELINES, pipelines);
    dispatch('emitEventUpdateCount', response);
  }
};

export const errorCallback = ({ dispatch }) => {
  dispatch('hideLoading');
  dispatch('shouldUpdateGraphDropdown', true);
  dispatch('toggleError', true);
};

// TODO HANDLE THIS!
export const emitEventUpdateCount = (store, response) => {
  const updatePipelinesEvent = new CustomEvent('update-pipelines-count', {
    detail: {
      pipelines: response,
    },
  });

 // notifiy to update the count in tabs
 // if (this.$el.parentElement) {
 //   this.$el.parentElement.dispatchEvent(updatePipelinesEvent);
 // }
};

export const stopPipeline = ({ dispatch, state, commit }, endpoint) => axios.post(`${endpoint}.json`)
  .then(() => {
    dispatch('refreshPipeline');
  })
  .catch(() => {
    createFlash(__('An error occurred while trying to stop the pipeline. Please try again.'));
  });

export const retryPipeline = ({ dispatch, state, commit }, endpoint) => axios.post(`${endpoint}.json`)
  .then(() => {
    dispatch('refreshPipeline');
  })
  .catch(() => {
    createFlash(__('An error occurred while trying to retry the pipeline. Please try again.'));
  });

export const refreshPipeline = ({ state, dispatch }) => {
  if (!state.isMakingRequest) {
    dispatch('showLoading');
    dispatch('getPipelines')
      .then(response => dispatch('successCallback', response))
      .catch(() => {
        dispatch('errorCallback');
        createFlash(__('An error occurred while fetching the pipelines. Please try again.'));
      });
  }
};
