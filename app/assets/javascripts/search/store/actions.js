import axios from '~/lib/utils/axios_utils';
import Api from '~/api';
import createFlash from '~/flash';
import { __ } from '~/locale';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import * as types from './mutation_types';

/* private */
const getCount = ({ params, state, activeCount }) => {
  const globalSearchCountsPath = '/search/count';
  const url = Api.buildUrl(globalSearchCountsPath);

  // count is known for active tab, so return it and skip the Api call
  if (params.scope === state.query?.scope) {
    return { scope: params.scope, count: activeCount };
  }

  return axios
    .get(url, { params })
    .then(({ data }) => {
      return { scope: params.scope, count: data.count };
    })
    .catch((e) => {
      throw e;
    });
};

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

export const fetchSearchCounts = ({ commit, state }, { scopeTabs, activeCount }) => {
  commit(types.REQUEST_SEARCH_COUNTS, { scopeTabs, activeCount });
  const promises = scopeTabs.map((scope) =>
    getCount({ params: { ...state.query, scope }, state, activeCount }),
  );

  Promise.all(promises)
    .then((data) => {
      commit(types.RECEIVE_SEARCH_COUNTS_SUCCESS, data);
    })
    .catch(() => {
      createFlash({ message: __('There was an error fetching the Search Counts') });
    });
};

export const setQuery = ({ commit }, { key, value }) => {
  commit(types.SET_QUERY, { key, value });
};

export const applyQuery = ({ state }) => {
  visitUrl(setUrlParams({ ...state.query, page: null }));
};

export const resetQuery = ({ state }, snippets = false) => {
  let defaultQuery = {
    page: null,
    state: null,
    confidential: null,
    nav_source: null,
  };

  if (snippets) {
    defaultQuery = {
      snippets: true,
      group_id: null,
      project_id: null,
      ...defaultQuery,
    };
  }

  visitUrl(setUrlParams({ ...state.query, ...defaultQuery }));
};
