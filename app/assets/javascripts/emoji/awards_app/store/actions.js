import * as Sentry from '~/sentry/sentry_browser_wrapper';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import {
  SET_INITIAL_DATA,
  FETCH_AWARDS_SUCCESS,
  ADD_NEW_AWARD,
  REMOVE_AWARD,
} from './mutation_types';

export const setInitialData = ({ commit }, data) => commit(SET_INITIAL_DATA, data);

export const fetchAwards = async ({ commit, dispatch, state }, page = '1') => {
  try {
    const { data, headers } = await axios.get(joinPaths(gon.relative_url_root || '', state.path), {
      params: { per_page: 100, page },
    });
    const normalizedHeaders = normalizeHeaders(headers);
    const nextPage = normalizedHeaders['X-NEXT-PAGE'];

    commit(FETCH_AWARDS_SUCCESS, data);

    if (nextPage) {
      dispatch('fetchAwards', nextPage);
    }
  } catch (error) {
    Sentry.captureException(error);
  }
};

/**
 * Creates an intermediary award, used for display
 * until the real award is loaded from the backend.
 */
const newOptimisticAward = (name, state) => {
  const freeId = Math.min(...state.awards.map((a) => a.id), Number.MAX_SAFE_INTEGER) - 1;
  return {
    id: freeId,
    name,
    user: {
      id: window.gon.current_user_id,
      name: window.gon.current_user_fullname,
      username: window.gon.current_username,
    },
  };
};

export const toggleAward = async ({ commit, state }, name) => {
  const award = state.awards.find((a) => a.name === name && a.user.id === state.currentUserId);

  try {
    if (award) {
      commit(REMOVE_AWARD, award.id);

      await axios
        .delete(joinPaths(gon.relative_url_root || '', `${state.path}/${award.id}`))
        .catch((err) => {
          commit(ADD_NEW_AWARD, award);

          throw err;
        });
    } else {
      const optimisticAward = newOptimisticAward(name, state);

      commit(ADD_NEW_AWARD, optimisticAward);

      const { data } = await axios
        .post(joinPaths(gon.relative_url_root || '', state.path), {
          name,
        })
        .finally(() => {
          commit(REMOVE_AWARD, optimisticAward.id);
        });

      commit(ADD_NEW_AWARD, data);
    }
  } catch (error) {
    Sentry.captureException(error);
  }
};
