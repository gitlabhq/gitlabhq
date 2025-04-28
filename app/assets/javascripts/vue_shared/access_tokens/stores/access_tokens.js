import { defineStore } from 'pinia';
import { createAlert } from '~/alert';
import Api from '~/api';
import { smoothScrollTop } from '~/behaviors/smooth_scroll';
import axios from '~/lib/utils/axios_utils';
import {
  convertObjectPropsToCamelCase,
  normalizeHeaders,
  parseIntPagination,
} from '~/lib/utils/common_utils';
import { joinPaths } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import { SORT_OPTIONS, DEFAULT_SORT } from '~/access_tokens/constants';
import { serializeParams, update2WeekFromNow } from '../utils';

/**
 * @typedef {{type: string, value: {data: string, operator: string}}} Filter
 * @typedef {Array<string|Filter>} Filters
 */

/**
 * Fetch access tokens
 *
 * @param {Object} options
 * @param {string} options.url
 * @param {string|number} options.id
 * @param {Object<string, string|number>} options.params
 * @param {string} options.sort
 */
const fetchTokens = async ({ url, id, params, sort }) => {
  const { data, headers } = await axios.get(url, {
    params: { user_id: id, sort, ...params },
  });
  const { perPage, total } = parseIntPagination(normalizeHeaders(headers));

  return { data, perPage, total };
};

export const useAccessTokens = defineStore('accessTokens', {
  state() {
    return {
      alert: null,
      busy: false,
      /** @type {Filters} */
      filters: [],
      id: null,
      page: 1,
      perPage: null,
      showCreateForm: false,
      token: null, // New and rotated token
      tokens: [],
      total: 0,
      urlCreate: '',
      urlRevoke: '',
      urlRotate: '',
      urlShow: '',
      sorting: DEFAULT_SORT,
      /** @type{Array<{title: string, tooltipTitle: string, filters: Filters, value: number}>} */
      statistics: [],
    };
  },
  actions: {
    /**
     * @param {Object} options
     *   @param {string} options.name
     *   @param {string} options.description
     *   @param {string} options.expiresAt
     *   @param {string[]} options.scopes
     */
    async createToken({ name, description, expiresAt, scopes }) {
      this.alert?.dismiss();
      this.alert = null;
      this.busy = true;
      try {
        const url = Api.buildUrl(this.urlCreate.replace(':id', this.id));
        const { data } = await axios.post(url, {
          name,
          description,
          expires_at: expiresAt,
          scopes,
        });
        this.token = data.token;
        this.showCreateForm = false;
        // Reset pagination because after creation the token may appear on a different page.
        this.page = 1;
        await this.fetchTokens({ clearAlert: false });
      } catch (error) {
        const responseData = error?.response?.data;
        const message =
          responseData?.error ??
          responseData?.message ??
          s__('AccessTokens|An error occurred while creating the token.');
        this.alert = createAlert({ message });
      } finally {
        smoothScrollTop();
        this.busy = false;
      }
    },
    async fetchStatistics() {
      try {
        const updatedFilters = update2WeekFromNow();
        this.statistics = await Promise.all(
          updatedFilters.map(async (stat) => {
            const params = serializeParams(stat.filters);
            const url = Api.buildUrl(this.urlShow.replace(':id', this.id));
            const { total } = await fetchTokens({
              url,
              id: this.id,
              params,
              sort: this.sort,
            });
            return {
              title: stat.title,
              tooltipTitle: stat.tooltipTitle,
              filters: stat.filters,
              value: total,
            };
          }),
        );
      } catch {
        if (!this.alert) {
          this.alert = createAlert({
            message: s__('AccessTokens|Failed to fetch statistics.'),
          });
        }
      }
    },
    async fetchTokens({ clearAlert } = { clearAlert: true }) {
      if (clearAlert) {
        this.alert?.dismiss();
        this.alert = null;
      }
      this.busy = true;
      try {
        const url = Api.buildUrl(this.urlShow.replace(':id', this.id));
        const { data, perPage, total } = await fetchTokens({
          url,
          id: this.id,
          params: this.params,
          sort: this.sort,
        });
        this.tokens = convertObjectPropsToCamelCase(data, { deep: true });
        this.perPage = perPage;
        this.total = total;
        await this.fetchStatistics();
      } catch {
        this.alert = createAlert({
          message: s__('AccessTokens|An error occurred while fetching the tokens.'),
        });
      } finally {
        this.busy = false;
      }
    },
    /**
     * @param {number} tokenId
     */
    async revokeToken(tokenId) {
      this.alert?.dismiss();
      this.alert = null;
      this.busy = true;
      this.showCreateForm = false;
      try {
        const url = Api.buildUrl(this.urlRevoke.replace(':id', this.id));
        await axios.delete(joinPaths(url, `${tokenId}`));
        this.alert = createAlert({
          message: s__('AccessTokens|The token was revoked successfully.'),
          variant: 'success',
        });
        // Reset pagination to avoid situations like: page 2 contains only one token and after it
        // is revoked the page shows `No tokens access tokens` (but there are 20 tokens on page 1).
        this.page = 1;
        await this.fetchTokens({ clearAlert: false });
      } catch {
        this.alert = createAlert({
          message: s__('AccessTokens|An error occurred while revoking the token.'),
        });
      } finally {
        smoothScrollTop();
        this.busy = false;
      }
    },
    /**
     * @param {number} tokenId
     * @param {string} expiresAt
     */
    async rotateToken(tokenId, expiresAt) {
      this.alert?.dismiss();
      this.alert = null;
      this.busy = true;
      this.showCreateForm = false;
      try {
        const url = Api.buildUrl(this.urlRotate.replace(':id', this.id));
        const { data } = await axios.post(joinPaths(url, `${tokenId}`, 'rotate'), {
          expires_at: expiresAt,
        });
        this.token = data.token;
        // Reset pagination because after rotation the token may appear on a different page.
        this.page = 1;
        await this.fetchTokens({ clearAlert: false });
      } catch (error) {
        const responseData = error?.response?.data;
        const message =
          responseData?.error ??
          responseData?.message ??
          s__('AccessTokens|An error occurred while rotating the token.');
        this.alert = createAlert({ message });
      } finally {
        smoothScrollTop();
        this.busy = false;
      }
    },
    /**
     * @param {Filters} filters
     */
    setFilters(filters) {
      this.filters = filters;
    },
    /**
     * @param {number} page
     */
    setPage(page) {
      smoothScrollTop();
      this.page = page;
    },
    /**
     * @param {boolean} value
     */
    setShowCreateForm(value) {
      this.showCreateForm = value;
    },
    /**
     * @param {string} token
     */
    setToken(token) {
      this.token = token;
    },
    /**
     * @param {{isAsc: boolean, value: string}} sorting
     */
    setSorting(sorting) {
      this.sorting = sorting;
    },
    /**
     * @param {Object} options
     *    @param {Filters} options.filters
     *    @param {number} options.id
     *    @param {string} options.urlCreate
     *    @param {string} options.urlRevoke
     *    @param {string} options.urlRotate
     *    @param {string} options.urlShow
     */
    setup({ filters, id, urlCreate, urlRevoke, urlRotate, urlShow }) {
      this.filters = filters;
      this.id = id;
      this.urlCreate = urlCreate;
      this.urlRevoke = urlRevoke;
      this.urlRotate = urlRotate;
      this.urlShow = urlShow;
    },
  },
  getters: {
    params() {
      return serializeParams(this.filters, this.page);
    },
    sort() {
      const { value, isAsc } = this.sorting;
      const sortOption = SORT_OPTIONS.find((option) => option.value === value);

      return isAsc ? sortOption.sort.asc : sortOption.sort.desc;
    },
  },
});
