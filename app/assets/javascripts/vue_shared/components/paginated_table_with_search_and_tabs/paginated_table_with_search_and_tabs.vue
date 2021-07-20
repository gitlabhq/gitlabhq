<script>
import { GlAlert, GlBadge, GlPagination, GlTab, GlTabs } from '@gitlab/ui';
import Api from '~/api';
import { updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import AuthorToken from '~/vue_shared/components/filtered_search_bar/tokens/author_token.vue';
import { initialPaginationState, defaultI18n, defaultPageSize } from './constants';
import { isAny } from './utils';

export default {
  defaultI18n,
  components: {
    GlAlert,
    GlBadge,
    GlPagination,
    GlTabs,
    GlTab,
    FilteredSearchBar,
  },
  inject: {
    projectPath: {
      default: '',
    },
    textQuery: {
      default: '',
    },
    assigneeUsernameQuery: {
      default: '',
    },
    authorUsernameQuery: {
      default: '',
    },
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
    itemsCount: {
      type: Object,
      required: false,
      default: () => {},
    },
    pageInfo: {
      type: Object,
      required: false,
      default: () => {},
    },
    statusTabs: {
      type: Array,
      required: true,
    },
    showItems: {
      type: Boolean,
      required: false,
      default: true,
    },
    showErrorMsg: {
      type: Boolean,
      required: true,
    },
    trackViewsOptions: {
      type: Object,
      required: true,
    },
    i18n: {
      type: Object,
      required: true,
    },
    serverErrorMessage: {
      type: String,
      required: false,
      default: '',
    },
    filterSearchKey: {
      type: String,
      required: true,
    },
    filterSearchTokens: {
      type: Array,
      required: false,
      default: () => ['author_username', 'assignee_username'],
    },
  },
  data() {
    return {
      searchTerm: this.textQuery,
      authorUsername: this.authorUsernameQuery,
      assigneeUsername: this.assigneeUsernameQuery,
      filterParams: {},
      pagination: initialPaginationState,
      filteredByStatus: '',
      statusFilter: '',
    };
  },
  computed: {
    defaultTokens() {
      return [
        {
          type: 'author_username',
          icon: 'user',
          title: __('Author'),
          unique: true,
          symbol: '@',
          token: AuthorToken,
          operators: OPERATOR_IS_ONLY,
          fetchPath: this.projectPath,
          fetchAuthors: Api.projectUsers.bind(Api),
        },
        {
          type: 'assignee_username',
          icon: 'user',
          title: __('Assignee'),
          unique: true,
          symbol: '@',
          token: AuthorToken,
          operators: OPERATOR_IS_ONLY,
          fetchPath: this.projectPath,
          fetchAuthors: Api.projectUsers.bind(Api),
        },
      ];
    },
    filteredSearchTokens() {
      return this.defaultTokens.filter(({ type }) => this.filterSearchTokens.includes(type));
    },
    filteredSearchValue() {
      const value = [];

      if (this.authorUsername) {
        value.push({
          type: 'author_username',
          value: { data: this.authorUsername },
        });
      }

      if (this.assigneeUsername) {
        value.push({
          type: 'assignee_username',
          value: { data: this.assigneeUsername },
        });
      }

      if (this.searchTerm) {
        value.push(this.searchTerm);
      }

      return value;
    },
    itemsForCurrentTab() {
      return this.itemsCount?.[this.filteredByStatus.toLowerCase()] ?? 0;
    },
    showPaginationControls() {
      return Boolean(this.pageInfo?.hasNextPage || this.pageInfo?.hasPreviousPage);
    },
    previousPage() {
      return Math.max(this.pagination.page - 1, 0);
    },
    nextPage() {
      const nextPage = this.pagination.page + 1;
      return nextPage > Math.ceil(this.itemsForCurrentTab / defaultPageSize) ? null : nextPage;
    },
  },
  mounted() {
    this.trackPageViews();
  },
  methods: {
    filterItemsByStatus(tabIndex) {
      this.resetPagination();
      const activeStatusTab = this.statusTabs[tabIndex];

      if (activeStatusTab == null) {
        return;
      }

      const { filters, status } = this.statusTabs[tabIndex];
      this.statusFilter = filters;
      this.filteredByStatus = status;

      this.$emit('tabs-changed', { filters, status });
    },
    handlePageChange(page) {
      const { startCursor, endCursor } = this.pageInfo;

      if (page > this.pagination.page) {
        this.pagination = {
          ...initialPaginationState,
          nextPageCursor: endCursor,
          page,
        };
      } else {
        this.pagination = {
          lastPageSize: defaultPageSize,
          firstPageSize: null,
          prevPageCursor: startCursor,
          nextPageCursor: '',
          page,
        };
      }

      this.$emit('page-changed', this.pagination);
    },
    resetPagination() {
      this.pagination = initialPaginationState;
      this.$emit('page-changed', this.pagination);
    },
    handleFilterItems(filters) {
      this.resetPagination();
      const filterParams = { authorUsername: '', assigneeUsername: '', search: '' };

      filters.forEach((filter) => {
        if (typeof filter === 'object') {
          switch (filter.type) {
            case 'author_username':
              filterParams.authorUsername = isAny(filter.value.data);
              break;
            case 'assignee_username':
              filterParams.assigneeUsername = isAny(filter.value.data);
              break;
            case 'filtered-search-term':
              if (filter.value.data !== '') filterParams.search = filter.value.data;
              break;
            default:
              break;
          }
        }
      });

      this.filterParams = filterParams;
      this.updateUrl();
      this.searchTerm = filterParams?.search;
      this.authorUsername = filterParams?.authorUsername;
      this.assigneeUsername = filterParams?.assigneeUsername;

      this.$emit('filters-changed', {
        searchTerm: this.searchTerm,
        authorUsername: this.authorUsername,
        assigneeUsername: this.assigneeUsername,
      });
    },
    updateUrl() {
      const { authorUsername, assigneeUsername, search } = this.filterParams || {};

      const params = {
        ...(authorUsername !== '' && { author_username: authorUsername }),
        ...(assigneeUsername !== '' && { assignee_username: assigneeUsername }),
        ...(search !== '' && { search }),
      };

      updateHistory({
        url: setUrlParams(params, window.location.href, true),
        title: document.title,
        replace: true,
      });
    },
    trackPageViews() {
      const { category, action } = this.trackViewsOptions;
      Tracking.event(category, action);
    },
  },
};
</script>
<template>
  <div class="incident-management-list">
    <gl-alert v-if="showErrorMsg" variant="danger" @dismiss="$emit('error-alert-dismissed')">
      <!-- eslint-disable-next-line vue/no-v-html -->
      <p v-html="serverErrorMessage || i18n.errorMsg"></p>
    </gl-alert>

    <div
      class="list-header gl-display-flex gl-justify-content-space-between gl-border-b-solid gl-border-b-1 gl-border-gray-100"
    >
      <gl-tabs content-class="gl-p-0" @input="filterItemsByStatus">
        <gl-tab v-for="tab in statusTabs" :key="tab.status" :data-testid="tab.status">
          <template #title>
            <span>{{ tab.title }}</span>
            <gl-badge v-if="itemsCount" pill size="sm" class="gl-tab-counter-badge">
              {{ itemsCount[tab.status.toLowerCase()] }}
            </gl-badge>
          </template>
        </gl-tab>
      </gl-tabs>

      <slot name="header-actions"></slot>
    </div>

    <div class="filtered-search-wrapper">
      <filtered-search-bar
        :namespace="projectPath"
        :search-input-placeholder="$options.defaultI18n.searchPlaceholder"
        :tokens="filteredSearchTokens"
        :initial-filter-value="filteredSearchValue"
        initial-sortby="created_desc"
        :recent-searches-storage-key="filterSearchKey"
        class="row-content-block"
        @onFilter="handleFilterItems"
      />
    </div>

    <h4 class="gl-display-block d-md-none my-3">
      <slot name="title"></slot>
    </h4>

    <slot v-if="showItems" name="table"></slot>

    <gl-pagination
      v-if="showPaginationControls"
      :value="pagination.page"
      :prev-page="previousPage"
      :next-page="nextPage"
      align="center"
      class="gl-pagination gl-mt-3"
      @input="handlePageChange"
    />

    <slot v-if="!showItems" name="empty-state"></slot>
  </div>
</template>
