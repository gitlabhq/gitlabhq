import * as Sentry from '@sentry/browser';
import axios from '~/lib/utils/axios_utils';
import { normalizeHeaders } from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import showToast from '~/vue_shared/plugins/global_toast';
import {
  SET_INITIAL_DATA,
  FETCH_AWARDS_SUCCESS,
  ADD_NEW_AWARD,
  REMOVE_AWARD,
} from './mutation_types';

export const setInitialData = ({ commit }, data) => commit(SET_INITIAL_DATA, data);

export const fetchAwards = async ({ commit, dispatch, state }, page = '1') => {
  try {
    const { data, headers } = await axios.get(state.path, { params: { per_page: 100, page } });
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

export const toggleAward = async ({ commit, state }, name) => {
  const award = state.awards.find((a) => a.name === name && a.user.id === state.currentUserId);

  try {
    if (award) {
      await axios.delete(`${state.path}/${award.id}`);

      commit(REMOVE_AWARD, award.id);

      showToast(__('Award removed'));
    } else {
      const { data } = await axios.post(state.path, { name });

      commit(ADD_NEW_AWARD, data);

      showToast(__('Award added'));
    }
  } catch (error) {
    Sentry.captureException(error);
  }
};
