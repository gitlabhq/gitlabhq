import Api from '~/api';
import axios from '~/lib/utils/axios_utils';
import { deprecatedCreateFlash as createFlash } from '~/flash';
import { DELETE_PACKAGE_ERROR_MESSAGE } from '~/packages/shared/constants';
import * as types from './mutation_types';
import {
  FETCH_PACKAGES_LIST_ERROR_MESSAGE,
  DELETE_PACKAGE_SUCCESS_MESSAGE,
  DEFAULT_PAGE,
  DEFAULT_PAGE_SIZE,
  MISSING_DELETE_PATH_ERROR,
} from '../constants';
import { getNewPaginationPage } from '../utils';

export const setInitialState = ({ commit }, data) => commit(types.SET_INITIAL_STATE, data);
export const setLoading = ({ commit }, data) => commit(types.SET_MAIN_LOADING, data);
export const setSorting = ({ commit }, data) => commit(types.SET_SORTING, data);
export const setSelectedType = ({ commit }, data) => commit(types.SET_SELECTED_TYPE, data);
export const setFilter = ({ commit }, data) => commit(types.SET_FILTER, data);

export const receivePackagesListSuccess = ({ commit }, { data, headers }) => {
  commit(types.SET_PACKAGE_LIST_SUCCESS, data);
  commit(types.SET_PAGINATION, headers);
};

export const requestPackagesList = ({ dispatch, state }, params = {}) => {
  dispatch('setLoading', true);

  const { page = DEFAULT_PAGE, per_page = DEFAULT_PAGE_SIZE } = params;
  const { sort, orderBy } = state.sorting;

  const type = state.selectedType?.type?.toLowerCase();
  const nameFilter = state.filterQuery?.toLowerCase();
  const packageFilters = { package_type: type, package_name: nameFilter };

  const apiMethod = state.config.isGroupPage ? 'groupPackages' : 'projectPackages';

  return Api[apiMethod](state.config.resourceId, {
    params: { page, per_page, sort, order_by: orderBy, ...packageFilters },
  })
    .then(({ data, headers }) => {
      dispatch('receivePackagesListSuccess', { data, headers });
    })
    .catch(() => {
      createFlash(FETCH_PACKAGES_LIST_ERROR_MESSAGE);
    })
    .finally(() => {
      dispatch('setLoading', false);
    });
};

export const requestDeletePackage = ({ dispatch, state }, { _links }) => {
  if (!_links || !_links.delete_api_path) {
    createFlash(DELETE_PACKAGE_ERROR_MESSAGE);
    const error = new Error(MISSING_DELETE_PATH_ERROR);
    return Promise.reject(error);
  }

  dispatch('setLoading', true);
  return axios
    .delete(_links.delete_api_path)
    .then(() => {
      const { page: currentPage, perPage, total } = state.pagination;
      const page = getNewPaginationPage(currentPage, perPage, total - 1);

      dispatch('requestPackagesList', { page });
      createFlash(DELETE_PACKAGE_SUCCESS_MESSAGE, 'success');
    })
    .catch(() => {
      dispatch('setLoading', false);
      createFlash(DELETE_PACKAGE_ERROR_MESSAGE);
    });
};
