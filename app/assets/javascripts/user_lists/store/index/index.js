import { defineStore } from 'pinia';
import Api from '~/api';
import { normalizeHeaders, parseIntPagination } from '~/lib/utils/common_utils';

export const useUserLists = defineStore('userLists', {
  state: () => ({
    userLists: [],
    alerts: [],
    count: 0,
    pageInfo: {},
    isLoading: true,
    hasError: false,
    options: {},
    projectId: null,
  }),
  actions: {
    setUserListsOptions(options = {}) {
      this.options = options;
    },
    async fetchUserLists() {
      this.isLoading = true;
      try {
        const { data, headers } = await Api.fetchFeatureFlagUserLists(
          this.projectId,
          this.options.page,
        );
        this.userLists = data || [];
        const paginationInfo = parseIntPagination(normalizeHeaders(headers));
        this.count = paginationInfo?.total ?? this.userLists.length;
        this.pageInfo = paginationInfo;
        this.hasError = false;
      } catch {
        this.hasError = true;
      } finally {
        this.isLoading = false;
      }
    },
    async deleteUserList(list) {
      this.userLists = this.userLists.filter((l) => l.iid !== list.iid);
      try {
        await Api.deleteFeatureFlagUserList(this.projectId, list.iid);
        await this.fetchUserLists();
      } catch (error) {
        const errorData = error?.response?.data ?? error;
        this.isLoading = false;
        this.hasError = false;
        this.alerts = [].concat(errorData.message);
        this.userLists = this.userLists.concat(list).sort((l1, l2) => l1.iid - l2.iid);
      }
    },
    clearAlert(index) {
      this.alerts.splice(index, 1);
    },
  },
});
