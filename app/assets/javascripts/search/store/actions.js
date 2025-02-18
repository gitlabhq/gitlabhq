import { omitBy } from 'lodash';
import Api from '~/api';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { visitUrl, setUrlParams, getNormalizedURL, updateHistory } from '~/lib/utils/url_utility';
import { logError } from '~/lib/logger';
import { __ } from '~/locale';
import { SCOPE_BLOB, SEARCH_TYPE_ZOEKT, LABEL_FILTER_PARAM } from '~/search/sidebar/constants';
import {
  GROUPS_LOCAL_STORAGE_KEY,
  PROJECTS_LOCAL_STORAGE_KEY,
  SIDEBAR_PARAMS,
  REGEX_PARAM,
  LS_REGEX_HANDLE,
} from '~/search/store/constants';
import * as types from './mutation_types';
import {
  loadDataFromLS,
  setFrequentItemToLS,
  mergeById,
  isSidebarDirty,
  getAggregationsUrl,
  prepareSearchAggregations,
  setDataToLS,
  skipBlobESCount,
} from './utils';

export const fetchGroups = ({ commit }, search) => {
  commit(types.REQUEST_GROUPS);
  Api.groups(search, { order_by: 'similarity' })
    .then((data) => {
      commit(types.RECEIVE_GROUPS_SUCCESS, data);
    })
    .catch(() => {
      createAlert({ message: __('There was a problem fetching groups.') });
      commit(types.RECEIVE_GROUPS_ERROR);
    });
};

export const fetchProjects = ({ commit, state }, search) => {
  commit(types.REQUEST_PROJECTS);
  const groupId = state.query?.group_id;

  const handleCatch = () => {
    createAlert({ message: __('There was an error fetching projects') });
    commit(types.RECEIVE_PROJECTS_ERROR);
  };
  const handleSuccess = ({ data }) => {
    commit(types.RECEIVE_PROJECTS_SUCCESS, data);
  };

  if (groupId) {
    Api.groupProjects(groupId, search, {
      order_by: 'similarity',
      with_shared: false,
      include_subgroups: true,
    })
      .then(handleSuccess)
      .catch(handleCatch);
  } else {
    // The .catch() is due to the API method not handling a rejection properly
    Api.projects(search, { order_by: 'similarity' }).then(handleSuccess).catch(handleCatch);
  }
};

export const preloadStoredFrequentItems = ({ commit }) => {
  const storedGroups = loadDataFromLS(GROUPS_LOCAL_STORAGE_KEY) || [];
  commit(types.LOAD_FREQUENT_ITEMS, { key: GROUPS_LOCAL_STORAGE_KEY, data: storedGroups });

  const storedProjects = loadDataFromLS(PROJECTS_LOCAL_STORAGE_KEY) || [];
  commit(types.LOAD_FREQUENT_ITEMS, { key: PROJECTS_LOCAL_STORAGE_KEY, data: storedProjects });
};

export const loadFrequentGroups = async ({ commit, state }) => {
  const storedData = state.frequentItems[GROUPS_LOCAL_STORAGE_KEY];
  const promises = storedData.map((d) => Api.group(d.id));
  try {
    const inflatedData = mergeById(await Promise.all(promises), storedData);
    commit(types.LOAD_FREQUENT_ITEMS, { key: GROUPS_LOCAL_STORAGE_KEY, data: inflatedData });
  } catch {
    createAlert({ message: __('There was a problem fetching recent groups.') });
  }
};

export const loadFrequentProjects = async ({ commit, state }) => {
  const storedData = state.frequentItems[PROJECTS_LOCAL_STORAGE_KEY];
  const promises = storedData.map((d) => Api.project(d.id).then((res) => res.data));
  try {
    const inflatedData = mergeById(await Promise.all(promises), storedData);
    commit(types.LOAD_FREQUENT_ITEMS, { key: PROJECTS_LOCAL_STORAGE_KEY, data: inflatedData });
  } catch {
    createAlert({ message: __('There was a problem fetching recent projects.') });
  }
};

export const setFrequentGroup = ({ state, commit }, item) => {
  const frequentItems = setFrequentItemToLS(GROUPS_LOCAL_STORAGE_KEY, state.frequentItems, item);
  commit(types.LOAD_FREQUENT_ITEMS, { key: GROUPS_LOCAL_STORAGE_KEY, data: frequentItems });
};

export const setFrequentProject = ({ state, commit }, item) => {
  const frequentItems = setFrequentItemToLS(PROJECTS_LOCAL_STORAGE_KEY, state.frequentItems, item);
  commit(types.LOAD_FREQUENT_ITEMS, { key: PROJECTS_LOCAL_STORAGE_KEY, data: frequentItems });
};

export const setQuery = ({ state, commit, getters }, { key, value }) => {
  commit(types.SET_QUERY, { key, value });

  if (SIDEBAR_PARAMS.includes(key)) {
    commit(types.SET_SIDEBAR_DIRTY, isSidebarDirty(state.query, state.urlQuery));
  }

  if (key === REGEX_PARAM) {
    setDataToLS(LS_REGEX_HANDLE, value);
  }

  if (
    state.searchType === SEARCH_TYPE_ZOEKT &&
    getters.currentScope === SCOPE_BLOB &&
    gon.features.zoektMultimatchFrontend
  ) {
    const newUrl = setUrlParams({ ...state.query }, window.location.href, false, true);
    updateHistory({ state: state.query, url: newUrl, replace: true });
  }
};

export const applyQuery = ({ state }) => {
  const query = omitBy(state.query, (item) => item === '');
  visitUrl(setUrlParams({ ...query, page: null }, window.location.href, true, true));
};

export const resetQuery = ({ state }) => {
  const resetParams = SIDEBAR_PARAMS.reduce((acc, param) => {
    acc[param] = null;
    return acc;
  }, {});

  visitUrl(
    setUrlParams(
      {
        ...state.query,
        page: null,
        ...resetParams,
      },
      undefined,
      true,
    ),
  );
};

export const closeLabel = ({ state, commit }, { title }) => {
  const labels = state?.query?.[LABEL_FILTER_PARAM].filter((labelName) => labelName !== title);
  setQuery({ state, commit }, { key: LABEL_FILTER_PARAM, value: labels });
};

export const setLabelFilterSearch = ({ commit }, { value }) => {
  commit(types.SET_LABEL_SEARCH_STRING, value);
};

export const fetchSidebarCount = ({ commit, state }) => {
  const items = Object.values(state.navigation)
    .filter(
      (navigationItem) =>
        !navigationItem.active &&
        navigationItem.count_link &&
        skipBlobESCount(state, navigationItem.scope),
    )
    .map((navItem) => {
      const navigationItem = { ...navItem };
      const modifications = {
        search: state.query?.search || '*',
      };

      if (navigationItem.scope === SCOPE_BLOB && loadDataFromLS(LS_REGEX_HANDLE)) {
        modifications[REGEX_PARAM] = true;
      }

      navigationItem.count_link = setUrlParams(
        modifications,
        getNormalizedURL(navigationItem.count_link),
      );

      return navigationItem;
    });

  const promises = items.map((navigationItem) =>
    axios
      .get(navigationItem.count_link)
      .then(({ data: { count } }) => {
        commit(types.RECEIVE_NAVIGATION_COUNT, { key: navigationItem.scope, count });
      })
      .catch((e) => logError(e)),
  );

  return Promise.all(promises);
};

export const fetchAllAggregation = ({ commit, state }) => {
  commit(types.REQUEST_AGGREGATIONS);
  return axios
    .get(getAggregationsUrl())
    .then(({ data }) => {
      commit(types.RECEIVE_AGGREGATIONS_SUCCESS, prepareSearchAggregations(state, data));
    })
    .catch((e) => {
      logError(e);
      commit(types.RECEIVE_AGGREGATIONS_ERROR);
    });
};
