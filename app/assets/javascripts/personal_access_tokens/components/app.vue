<script>
import { GlFilteredSearch, GlKeysetPagination, GlSorting } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import getUserPersonalAccessTokens from '../graphql/get_user_personal_access_tokens.query.graphql';
import {
  DEFAULT_FILTER,
  FILTER_OPTIONS,
  SORT_OPTIONS,
  DEFAULT_SORT,
  PAGE_SIZE,
} from '../constants';
import { convertFiltersToVariables } from '../utils';
import CreatePersonalAccessTokenButton from './create_personal_access_token_button.vue';
import PersonalAccessTokensTable from './personal_access_tokens_table.vue';
import PersonalAccessTokenDrawer from './personal_access_token_drawer.vue';
import PersonalAccessTokenStatistics from './personal_access_token_statistics.vue';

export default {
  name: 'PersonalAccessTokensApp',
  components: {
    PageHeading,
    GlFilteredSearch,
    GlSorting,
    GlKeysetPagination,
    CrudComponent,
    PersonalAccessTokensTable,
    CreatePersonalAccessTokenButton,
    PersonalAccessTokenDrawer,
    PersonalAccessTokenStatistics,
  },
  data() {
    return {
      tokens: {
        list: [],
        pageInfo: {},
      },
      filter: structuredClone(DEFAULT_FILTER),
      filterObject: convertFiltersToVariables(DEFAULT_FILTER),
      sort: structuredClone(DEFAULT_SORT),
      selectedToken: null,
      pagination: {
        first: PAGE_SIZE,
        after: null,
        last: null,
        before: null,
      },
    };
  },
  apollo: {
    tokens: {
      query: getUserPersonalAccessTokens,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          sort: this.currentSort,
          ...this.filterObject,
          ...this.pagination,
        };
      },
      update(data) {
        const { nodes, pageInfo } = data?.user?.personalAccessTokens || {};
        return {
          list: nodes,
          pageInfo,
        };
      },
      error() {
        createAlert({
          message: this.$options.i18n.fetchError,
          variant: VARIANT_DANGER,
        });
      },
    },
  },
  computed: {
    isLoading() {
      return Boolean(this.$apollo.queries.tokens.loading);
    },
    currentSort() {
      const sortingColumn = this.sort.value.toUpperCase();
      const sortingDirection = this.sort.isAsc ? 'ASC' : 'DESC';
      return `${sortingColumn}_${sortingDirection}`;
    },
    showPagination() {
      return this.tokens?.pageInfo?.hasNextPage || this.tokens?.pageInfo?.hasPreviousPage;
    },
  },
  methods: {
    handleFilter() {
      this.filterObject = convertFiltersToVariables(this.filter);

      this.$apollo.queries.tokens.refetch();
    },
    handleFilterClear() {
      this.filter = [];
      this.filterObject = {};

      this.$apollo.queries.tokens.refetch();
    },
    handleSortChange(value) {
      this.sort.value = value;
    },
    handleSortDirectionChange(value) {
      this.sort.isAsc = value;
    },
    onNextPage(item) {
      this.pagination = {
        first: PAGE_SIZE,
        after: item,
        last: null,
        before: null,
      };
    },
    onPrevPage(item) {
      this.pagination = {
        first: null,
        after: null,
        last: PAGE_SIZE,
        before: item,
      };
    },
    selectToken(token) {
      this.selectedToken = token;
    },
    handleStatisticsFilter(filter) {
      this.filter = filter;
      this.filterObject = convertFiltersToVariables(this.filter);

      this.$apollo.queries.tokens.refetch();
    },
  },
  i18n: {
    pageTitle: s__('AccessTokens|Personal access tokens'),
    pageDescription: s__(
      'AccessTokens|You can generate a personal access token for each application you use that needs access to the GitLab API. You can also use personal access tokens to authenticate against Git over HTTP. They are the only accepted password when you have Two-Factor Authentication (2FA) enabled.',
    ),
    searchPlaceholder: s__('AccessTokens|Search or filter access tokens…'),
    fetchError: s__('AccessTokens|An error occurred while fetching the tokens.'),
  },
  FILTER_OPTIONS,
  SORT_OPTIONS,
};
</script>

<template>
  <div class="gl-mb-5">
    <page-heading :heading="$options.i18n.pageTitle">
      <template #description>
        {{ $options.i18n.pageDescription }}
      </template>
    </page-heading>

    <personal-access-token-statistics @filter="handleStatisticsFilter" />

    <div class="gl-my-5 gl-flex gl-flex-col gl-gap-3 @md/panel:gl-flex-row">
      <gl-filtered-search
        v-model="filter"
        class="gl-min-w-0 gl-grow"
        :placeholder="$options.i18n.searchPlaceholder"
        :available-tokens="$options.FILTER_OPTIONS"
        terms-as-tokens
        @submit="handleFilter"
        @clear="handleFilterClear"
      />
      <!-- eslint-disable vue/v-on-event-hyphenation -->
      <gl-sorting
        block
        dropdown-class="gl-w-full !gl-flex"
        :is-ascending="sort.isAsc"
        :sort-by="sort.value"
        :sort-options="$options.SORT_OPTIONS"
        @sortByChange="handleSortChange"
        @sortDirectionChange="handleSortDirectionChange"
      />
      <!-- eslint-enable vue/v-on-event-hyphenation -->
    </div>

    <crud-component :title="$options.i18n.pageTitle">
      <template #actions>
        <create-personal-access-token-button />
      </template>

      <personal-access-tokens-table
        :tokens="tokens.list"
        :loading="isLoading"
        class="gl-mb-5"
        @select="selectToken"
      />

      <template #pagination>
        <gl-keyset-pagination
          v-if="showPagination"
          v-bind="tokens.pageInfo"
          @prev="onPrevPage"
          @next="onNextPage"
        />
      </template>
    </crud-component>

    <personal-access-token-drawer :token="selectedToken" @close="selectToken(null)" />
  </div>
</template>
