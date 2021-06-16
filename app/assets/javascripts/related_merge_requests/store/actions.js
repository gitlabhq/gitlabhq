import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';
import * as types from './mutation_types';

const REQUEST_PAGE_COUNT = 100;

export const setInitialState = ({ commit }, props) => {
  commit(types.SET_INITIAL_STATE, props);
};

export const requestData = ({ commit }) => commit(types.REQUEST_DATA);

export const receiveDataSuccess = ({ commit }, data) => commit(types.RECEIVE_DATA_SUCCESS, data);

export const receiveDataError = ({ commit }) => commit(types.RECEIVE_DATA_ERROR);

export const fetchMergeRequests = ({ state, dispatch }) => {
  dispatch('requestData');

  return axios
    .get(`${state.apiEndpoint}?per_page=${REQUEST_PAGE_COUNT}`)
    .then((res) => {
      const { headers, data } = res;
      const total = Number(normalizeHeaders(headers)['X-TOTAL']) || 0;

      dispatch('receiveDataSuccess', { data, total });
    })
    .catch(() => {
      dispatch('receiveDataError');
      createFlash({
        message: s__('Something went wrong while fetching related merge requests.'),
      });
    });
};
