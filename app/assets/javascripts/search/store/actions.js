import Api from '~/api';
import createFlash from '~/flash';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import * as types from './mutation_types';

export const fetchGroups = ({ commit }, search) => {
  commit(types.REQUEST_GROUPS);
  Api.groups(search)
    .then((data) => {
      commit(types.RECEIVE_GROUPS_SUCCESS, data);
    })
    .catch(() => {
      createFlash({ message: __('There was a problem fetching groups.') });
      commit(types.RECEIVE_GROUPS_ERROR);
    });
};

export const fetchProjects = ({ commit, state }, search) => {
  commit(types.REQUEST_PROJECTS);
  const groupId = state.query?.group_id;
  const callback = (data) => {
    if (data) {
      commit(types.RECEIVE_PROJECTS_SUCCESS, data);
    } else {
      createFlash({ message: __('There was an error fetching projects') });
      commit(types.RECEIVE_PROJECTS_ERROR);
    }
  };

  if (groupId) {
    Api.groupProjects(groupId, search, {}, callback);
  } else {
    // The .catch() is due to the API method not handling a rejection properly
    Api.projects(search, { order_by: 'id' }, callback).catch(() => {
      callback();
    });
  }
};

export const setQuery = ({ commit }, { key, value }) => {
  commit(types.SET_QUERY, { key, value });
};

export const applyQuery = ({ state }) => {
  visitUrl(setUrlParams({ ...state.query, page: null }));
};

export const resetQuery = ({ state }) => {
  visitUrl(setUrlParams({ ...state.query, page: null, state: null, confidential: null }));
};
