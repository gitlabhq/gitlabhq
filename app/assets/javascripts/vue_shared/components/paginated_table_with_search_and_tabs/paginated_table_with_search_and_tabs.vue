<script>
import { GlAlert, GlBadge, GlKeysetPagination, GlTab, GlTabs } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import Api from '~/api';
import { updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import {
  FILTERED_SEARCH_TERM,
  OPERATORS_IS,
  TOKEN_TITLE_ASSIGNEE,
  TOKEN_TITLE_AUTHOR,
  TOKEN_TYPE_ASSIGNEE,
  TOKEN_TYPE_AUTHOR,
} from '~/vue_shared/components/filtered_search_bar/constants';
import FilteredSearchBar from '~/vue_shared/components/filtered_search_bar/filtered_search_bar_root.vue';
import UserToken from '~/vue_shared/components/filtered_search_bar/tokens/user_token.vue';
import { initialPaginationState, defaultPageSize } from './constants';
import { isAny } from './utils';

export default {
  components: {
    GlAlert,
    GlBadge,
    GlKeysetPagination,
    GlTabs,
    GlTab,
    FilteredSearchBar,
  },
  directives: {
    SafeHtml,
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
    itemsCount: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    pageInfo: {
      type: Object,
      required: false,
      default: () => ({}),
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
      default: () => [TOKEN_TYPE_AUTHOR, TOKEN_TYPE_ASSIGNEE],
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
          type: TOKEN_TYPE_AUTHOR,
          icon: 'user',
          title: TOKEN_TITLE_AUTHOR,
          unique: true,
          symbol: '@',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS,
          fetchPath: this.projectPath,
          fetchUsers: Api.projectUsers.bind(Api),
        },
        {
          type: TOKEN_TYPE_ASSIGNEE,
          icon: 'user',
          title: TOKEN_TITLE_ASSIGNEE,
          unique: true,
          symbol: '@',
          token: UserToken,
          dataType: 'user',
          operators: OPERATORS_IS,
          fetchPath: this.projectPath,
          fetchUsers: Api.projectUsers.bind(Api),
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
          type: TOKEN_TYPE_AUTHOR,
          value: { data: this.authorUsername },
        });
      }

      if (this.assigneeUsername) {
        value.push({
          type: TOKEN_TYPE_ASSIGNEE,
          value: { data: this.assigneeUsername },
        });
      }

      if (this.searchTerm) {
        value.push(this.searchTerm);
      }

      return value;
    },
    showPaginationControls() {
      return Boolean(this.pageInfo?.hasNextPage || this.pageInfo?.hasPreviousPage);
    },
    paginationInfo() {
      return {
        hasNextPage: Boolean(this.pageInfo?.hasNextPage),
        hasPreviousPage: Boolean(this.pageInfo?.hasPreviousPage),
      };
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
    handleNextPage() {
      const { endCursor } = this.pageInfo;
      this.pagination = {
        ...initialPaginationState,
        nextPageCursor: endCursor,
      };
      this.$emit('page-changed', this.pagination);
    },
    handlePrevPage() {
      const { startCursor } = this.pageInfo;
      this.pagination = {
        lastPageSize: defaultPageSize,
        firstPageSize: null,
        prevPageCursor: startCursor,
        nextPageCursor: '',
      };
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
            case TOKEN_TYPE_AUTHOR:
              filterParams.authorUsername = isAny(filter.value.data);
              break;
            case TOKEN_TYPE_ASSIGNEE:
              filterParams.assigneeUsername = isAny(filter.value.data);
              break;
            case FILTERED_SEARCH_TERM:
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
        url: setUrlParams(params, { url: window.location.href, clearParams: true }),
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
  <div class="paginated-table-wrapper">
    <gl-alert v-if="showErrorMsg" variant="danger" @dismiss="$emit('error-alert-dismissed')">
      <span v-safe-html="serverErrorMessage || i18n.errorMsg"></span>
    </gl-alert>

    <div class="list-header gl-flex gl-justify-between">
      <gl-tabs content-class="gl-p-0" @input="filterItemsByStatus">
        <gl-tab v-for="tab in statusTabs" :key="tab.status" :data-testid="tab.status">
          <template #title>
            <span>{{ tab.title }}</span>
            <gl-badge v-if="itemsCount" pill class="gl-tab-counter-badge">
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
        :tokens="filteredSearchTokens"
        :initial-filter-value="filteredSearchValue"
        initial-sortby="created_desc"
        :recent-searches-storage-key="filterSearchKey"
        :class="{ 'gl-border-b-0': showItems }"
        class="row-content-block"
        @onFilter="handleFilterItems"
      />
    </div>

    <h4 class="gl-my-5 gl-block @md/panel:gl-hidden">
      <slot name="title"></slot>
    </h4>

    <slot v-if="showItems" name="table"></slot>

    <gl-keyset-pagination
      v-if="showPaginationControls"
      v-bind="paginationInfo"
      class="gl-my-6 gl-flex gl-justify-center"
      @prev="handlePrevPage"
      @next="handleNextPage"
    />

    <slot v-if="!showItems" name="empty-state"></slot>
  </div>
</template>
