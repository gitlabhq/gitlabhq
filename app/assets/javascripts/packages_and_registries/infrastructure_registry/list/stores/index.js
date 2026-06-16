import { defineStore } from 'pinia';
import Api from '~/api';
import { createAlert, VARIANT_SUCCESS } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { DELETE_PACKAGE_ERROR_MESSAGE } from '~/packages_and_registries/shared/constants';
import { beautifyPath } from '~/packages_and_registries/shared/utils';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import { DEFAULT_PAGE_SIZE } from '~/vue_shared/issuable/list/constants';
import {
  FETCH_PACKAGES_LIST_ERROR_MESSAGE,
  DELETE_PACKAGE_SUCCESS_MESSAGE,
  DEFAULT_PAGE,
  LIST_KEY_PROJECT,
  MISSING_DELETE_PATH_ERROR,
  TERRAFORM_SEARCH_TYPE,
} from '../constants';
import { getNewPaginationPage } from '../utils';

export const useInfrastructureList = defineStore('infrastructureList', {
  state: () => ({
    isLoading: false,
    packages: [],
    pagination: {},
    sorting: {
      sort: 'desc',
      orderBy: 'created_at',
    },
    filter: [],
  }),
  getters: {
    getList: (state) =>
      state.packages.map((p) => ({
        ...p,
        projectPathName: beautifyPath(p[LIST_KEY_PROJECT]),
      })),
  },
  actions: {
    setLoading(isLoading) {
      this.isLoading = isLoading;
    },
    setSorting(sorting) {
      this.sorting = { ...this.sorting, ...sorting };
    },
    setFilter(filter) {
      this.filter = filter;
    },
    async requestPackagesList(params = {}) {
      this.isLoading = true;
      try {
        const {
          isGroupPage = false,
          page = DEFAULT_PAGE,
          per_page: perPage = DEFAULT_PAGE_SIZE,
          resourceId,
        } = params;
        const { sort, orderBy } = this.sorting;
        const type = TERRAFORM_SEARCH_TYPE;
        const name = this.filter.find((f) => f.type === FILTERED_SEARCH_TERM);
        const packageFilters = {
          package_type: type?.value?.data,
          package_name: name?.value?.data,
        };
        const apiMethod = isGroupPage ? 'groupPackages' : 'projectPackages';

        const { data, headers } = await Api[apiMethod](resourceId, {
          params: { page, per_page: perPage, sort, order_by: orderBy, ...packageFilters },
        });

        this.packages = data;
        this.pagination = parseIntPagination(normalizeHeaders(headers));
      } catch {
        createAlert({
          message: FETCH_PACKAGES_LIST_ERROR_MESSAGE,
        });
      } finally {
        this.isLoading = false;
      }
    },
    async requestDeletePackage({ _links, isGroupPage, resourceId }) {
      if (!_links || !_links.delete_api_path) {
        createAlert({
          message: DELETE_PACKAGE_ERROR_MESSAGE,
        });
        throw new Error(MISSING_DELETE_PATH_ERROR);
      }

      this.isLoading = true;
      try {
        await axios.delete(_links.delete_api_path);
      } catch (error) {
        this.isLoading = false;
        createAlert({
          message: error?.response?.data?.message || DELETE_PACKAGE_ERROR_MESSAGE,
        });
        return;
      }

      const { page: currentPage, perPage, total } = this.pagination;
      const page = getNewPaginationPage(currentPage, perPage, total - 1);

      this.requestPackagesList({ page, isGroupPage, resourceId });
      createAlert({
        message: DELETE_PACKAGE_SUCCESS_MESSAGE,
        variant: VARIANT_SUCCESS,
      });
    },
  },
});
