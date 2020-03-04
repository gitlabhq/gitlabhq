import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import axios from '~/lib/utils/axios_utils';
import flash from '~/flash';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const fetchClusters = ({ state, commit }) => {
  return axios
    .get(state.endpoint)
    .then(({ data }) => {
      commit(types.SET_CLUSTERS_DATA, convertObjectPropsToCamelCase(data, { deep: true }));
      commit(types.SET_LOADING_STATE, false);
    })
    .catch(() => flash(__('An error occurred while loading clusters')));
};

// prevent babel-plugin-rewire from generating an invalid default during karma tests
export default () => {};
