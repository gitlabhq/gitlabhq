import { SET_ERROR_MESSAGE } from './mutation_types';

export default {
  [SET_ERROR_MESSAGE](state, errorMessage) {
    state.errorMessage = errorMessage;
  },
};
