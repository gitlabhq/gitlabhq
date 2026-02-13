<script>
import { GlFilteredSearch, GlKeysetPagination, GlSorting } from '@gitlab/ui';
import { s__ } from '~/locale';
import { createAlert, VARIANT_DANGER } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { TYPENAME_USER } from '~/graphql_shared/constants';
import { fetchPolicies } from '~/lib/graphql';
import { updateHistory, setUrlParams } from '~/lib/utils/url_utility';
import {
  initializeFilterFromQueryParams,
  initializeSortFromQueryParams,
  convertFiltersToQueryParams,
  convertSortToQueryParams,
  convertFiltersToVariables,
} from '../utils';
import getUserPersonalAccessTokens from '../graphql/get_user_personal_access_tokens.query.graphql';
import { FILTER_OPTIONS, SORT_OPTIONS, PAGE_SIZE, ACTIONS } from '../constants';
import CreatePersonalAccessTokenDropdown from './create_personal_access_token_dropdown.vue';
import PersonalAccessTokensTable from './personal_access_tokens_table.vue';
import PersonalAccessTokenDrawer from './personal_access_token_drawer.vue';
import PersonalAccessTokenStatistics from './personal_access_token_statistics.vue';
import PersonalAccessTokenActions from './personal_access_token_actions.vue';
import RotatedPersonalAccessToken from './rotated_personal_access_token.vue';

export default {
  name: 'PersonalAccessTokensApp',
  components: {
    PageHeading,
    GlFilteredSearch,
    GlSorting,
    GlKeysetPagination,
    CrudComponent,
    PersonalAccessTokensTable,
    CreatePersonalAccessTokenDropdown,
    PersonalAccessTokenDrawer,
    PersonalAccessTokenStatistics,
    PersonalAccessTokenActions,
    RotatedPersonalAccessToken,
  },
  data() {
    const filter = initializeFilterFromQueryParams();
    const sort = initializeSortFromQueryParams();

    return {
      tokens: {
        list: [],
        pageInfo: {},
      },
      filter,
      filterObject: convertFiltersToVariables(filter),
      sort,
      selectedToken: null,
      selectedActionableToken: {
        token: null,
        action: null,
      },
      rotatedToken: null,
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
      fetchPolicies: fetchPolicies.CACHE_AND_NETWORK,
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
  watch: {
    filterObject: {
      handler() {
        this.updateQueryParams();
      },
      deep: true,
    },
    sort: {
      handler() {
        this.updateQueryParams();
      },
      deep: true,
    },
  },
  mounted() {
    this.updateQueryParams();
  },
  methods: {
    updateQueryParams() {
      const params = {
        ...convertFiltersToQueryParams(this.filterObject),
        ...convertSortToQueryParams(this.sort),
      };

      updateHistory({
        url: setUrlParams(params, {
          url: window.location.href,
          clearParams: true,
          decodeParams: true,
        }),
        title: document.title,
        replace: true,
      });
    },
    handleFilter() {
      this.filterObject = convertFiltersToVariables(this.filter);
    },
    handleFilterClear() {
      this.filter = [];
      this.filterObject = {};
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
    clearSelectedToken() {
      this.selectedToken = null;
    },
    selectActionableToken(token, action) {
      this.selectedActionableToken = { token, action };
    },
    clearActionableToken() {
      this.selectedActionableToken = { token: null, action: null };
    },
    handleTokenRotated(token) {
      this.rotatedToken = token;

      this.clearSelectedToken();
    },
    handleStatisticsFilter(filter) {
      this.filter = filter;
      this.filterObject = convertFiltersToVariables(this.filter);
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
  ACTIONS,
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

    <rotated-personal-access-token v-if="rotatedToken" v-model="rotatedToken" />

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
        <create-personal-access-token-dropdown />
      </template>

      <personal-access-tokens-table
        :tokens="tokens.list"
        :loading="isLoading"
        class="gl-mb-5"
        @select="selectToken"
        @rotate="selectActionableToken($event, $options.ACTIONS.ROTATE)"
        @revoke="selectActionableToken($event, $options.ACTIONS.REVOKE)"
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

    <personal-access-token-drawer
      :token="selectedToken"
      @close="clearSelectedToken"
      @rotate="selectActionableToken($event, $options.ACTIONS.ROTATE)"
      @revoke="selectActionableToken($event, $options.ACTIONS.REVOKE)"
    />

    <personal-access-token-actions
      :token="selectedActionableToken.token"
      :action="selectedActionableToken.action"
      @close="clearActionableToken"
      @rotated="handleTokenRotated"
      @revoked="clearSelectedToken"
    />
  </div>
</template>
