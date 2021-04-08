import {
  SET_INITIAL_DATA,
  FETCH_AWARDS_SUCCESS,
  ADD_NEW_AWARD,
  REMOVE_AWARD,
} from './mutation_types';

export default {
  [SET_INITIAL_DATA](state, { path, currentUserId, canAwardEmoji }) {
    state.path = path;
    state.currentUserId = currentUserId;
    state.canAwardEmoji = canAwardEmoji;
  },
  [FETCH_AWARDS_SUCCESS](state, data) {
    state.awards.push(...data);
  },
  [ADD_NEW_AWARD](state, data) {
    state.awards.push(data);
  },
  [REMOVE_AWARD](state, awardId) {
    state.awards = state.awards.filter(({ id }) => id !== awardId);
  },
};
