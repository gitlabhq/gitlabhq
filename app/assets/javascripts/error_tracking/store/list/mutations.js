import * as types from './mutation_types';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';

export default {
  [types.SET_ERRORS](state, data) {
    state.errors = convertObjectPropsToCamelCase(data, { deep: true });
  },
  [types.SET_EXTERNAL_URL](state, url) {
    state.externalUrl = url;
  },
  [types.SET_LOADING](state, loading) {
    state.loading = loading;
  },
};
