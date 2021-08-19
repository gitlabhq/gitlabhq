import { SET_ALERT } from './mutation_types';

export default {
  [SET_ALERT](state, { title, message, variant, linkUrl } = {}) {
    state.alert = { title, message, variant, linkUrl };
  },
};
