import { defineStore } from 'pinia';
import axios from '~/lib/utils/axios_utils';
import { parseIntPagination, normalizeHeaders } from '~/lib/utils/common_utils';
import { joinPaths } from '~/lib/utils/url_utility';

import { createAlert, VARIANT_INFO } from '~/alert';
import { s__ } from '~/locale';

export const useServiceAccounts = defineStore('serviceAccounts', {
  state() {
    return {
      alert: null,
      serviceAccounts: [],
      serviceAccount: null,
      serviceAccountCount: 0,
      busy: false,
      url: '',
      page: 1,
      perPage: 8,
      deleteType: null,
      createEditType: null,
      createEditError: null,
    };
  },
  actions: {
    async fetchServiceAccounts(url, { page, clearAlert = true }) {
      this.url = url;
      this.page = page;

      if (clearAlert) {
        this.clearAlert();
      }
      this.busy = true;

      try {
        const { data, headers } = await axios.get(url, {
          params: {
            page,
            per_page: this.perPage,
            orderBy: 'name',
          },
        });

        const { total } = parseIntPagination(normalizeHeaders(headers));

        this.serviceAccountCount = total;
        this.serviceAccounts = data;
      } catch {
        this.alert = createAlert({
          message: s__('ServiceAccounts|An error occurred while fetching the service accounts.'),
        });
      } finally {
        this.busy = false;
      }
    },
    setServiceAccount(account) {
      this.serviceAccount = account;
    },
    setDeleteType(deleteType) {
      this.deleteType = deleteType;
    },
    setCreateEditType(actionType) {
      this.createEditType = actionType;
    },
    clearAlert() {
      this.alert?.dismiss();
      this.alert = null;
      this.createEditError = null;
    },
    async createServiceAccount(url, values) {
      this.busy = true;
      this.clearAlert();

      try {
        await axios.post(url, values);

        this.alert = createAlert({
          message: s__('ServiceAccounts|The service account was created.'),
          variant: VARIANT_INFO,
        });
        this.createEditType = null;

        await this.fetchServiceAccounts(this.url, { page: 1, clearAlert: false });
      } catch (error) {
        this.createEditError =
          error.response?.data?.message ??
          s__('ServiceAccounts|An error occurred creating the service account.');
      } finally {
        this.busy = false;
      }
    },
    async editServiceAccount(url, values) {
      this.busy = true;
      this.clearAlert();

      try {
        const href = joinPaths(url, `${this.serviceAccount.id}`);
        const { email, ...valuesWithoutEmail } = values;

        if (email == null) {
          await axios.patch(href, valuesWithoutEmail);
        } else {
          await axios.patch(href, values);
        }

        this.alert = createAlert({
          message: s__('ServiceAccounts|The service account was updated.'),
          variant: VARIANT_INFO,
        });
        this.createEditType = null;
        await this.fetchServiceAccounts(this.url, { page: 1, clearAlert: false });
      } catch (error) {
        this.createEditError =
          error.response?.data?.message ??
          s__('ServiceAccounts|An error occurred updating the service account.');
      } finally {
        this.busy = false;
      }
    },
    async deleteUser(url) {
      this.busy = true;
      this.clearAlert();
      const serviceAccountId = this.serviceAccount.id;
      try {
        const href = joinPaths(url, `${serviceAccountId}`);
        await axios.delete(href, {
          data: {
            id: serviceAccountId,
            hard_delete: this.deleteType === 'hard',
          },
        });
        this.alert = createAlert({
          message: s__('ServiceAccounts|The service account is being deleted.'),
          variant: VARIANT_INFO,
        });
        await this.fetchServiceAccounts(this.url, { page: 1, clearAlert: false });
      } catch {
        this.alert = createAlert({
          message: s__('ServiceAccounts|An error occurred while deleting the service account.'),
        });
      } finally {
        this.deleteType = null;
        this.busy = false;
      }
    },
  },
  getters: {},
});
