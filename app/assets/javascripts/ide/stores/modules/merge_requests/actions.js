import { __ } from '../../../../locale';
import Api from '../../../../api';
import flash from '../../../../flash';
import router from '../../../ide_router';
import { scopes } from './constants';
import * as types from './mutation_types';
import * as rootTypes from '../../mutation_types';

export const requestMergeRequests = ({ commit }, type) =>
  commit(types.REQUEST_MERGE_REQUESTS, type);
export const receiveMergeRequestsError = ({ commit }, type) => {
  flash(__('Error loading merge requests.'));
  commit(types.RECEIVE_MERGE_REQUESTS_ERROR, type);
};
export const receiveMergeRequestsSuccess = ({ commit }, { type, data }) =>
  commit(types.RECEIVE_MERGE_REQUESTS_SUCCESS, { type, data });

export const fetchMergeRequests = ({ dispatch, state: { state } }, { type, search = '' }) => {
  const scope = scopes[type];
  dispatch('requestMergeRequests', type);
  dispatch('resetMergeRequests', type);

  Api.mergeRequests({ scope, state, search })
    .then(({ data }) => dispatch('receiveMergeRequestsSuccess', { type, data }))
    .catch(() => dispatch('receiveMergeRequestsError', type));
};

export const resetMergeRequests = ({ commit }, type) => commit(types.RESET_MERGE_REQUESTS, type);

export const openMergeRequest = ({ commit, dispatch }, { projectPath, id }) => {
  commit(rootTypes.CLEAR_PROJECTS, null, { root: true });
  commit(rootTypes.SET_CURRENT_MERGE_REQUEST, `${id}`, { root: true });
  commit(rootTypes.RESET_OPEN_FILES, null, { root: true });
  dispatch('pipelines/stopPipelinePolling', null, { root: true });
  dispatch('pipelines/clearEtagPoll', null, { root: true });
  dispatch('pipelines/resetLatestPipeline', null, { root: true });
  dispatch('setCurrentBranchId', '', { root: true });

  router.push(`/project/${projectPath}/merge_requests/${id}`);
};

export default () => {};
