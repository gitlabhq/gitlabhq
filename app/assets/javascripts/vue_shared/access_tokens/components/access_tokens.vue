<script>
import { GlButton, GlFilteredSearch, GlPagination, GlSorting } from '@gitlab/ui';
import { mapActions, mapState } from 'pinia';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { scrollTo } from '~/lib/utils/scroll_utils';
import { FILTER_OPTIONS, SORT_OPTIONS } from '~/access_tokens/constants';
import { initializeValuesFromQuery } from '~/access_tokens/utils';
import { navigateToQuery } from '../utils';

import { useAccessTokens } from '../stores/access_tokens';
import AccessToken from './access_token.vue';
import AccessTokenForm from './access_token_form.vue';
import AccessTokenTable from './access_token_table.vue';
import AccessTokenStatistics from './access_token_statistics.vue';
import UserAvatar from './user_avatar.vue';

export default {
  name: 'AccessTokens',
  components: {
    GlButton,
    GlFilteredSearch,
    GlPagination,
    GlSorting,
    PageHeading,
    AccessToken,
    AccessTokenForm,
    AccessTokenTable,
    AccessTokenStatistics,
    UserAvatar,
  },
  inject: ['accessTokenCreate', 'accessTokenRevoke', 'accessTokenRotate', 'accessTokenShow'],
  props: {
    id: {
      type: Number,
      required: true,
    },
    showAvatar: {
      type: Boolean,
      required: false,
      default: false,
    },
    tokenName: {
      type: String,
      required: false,
      default: '',
    },
    tokenDescription: {
      type: String,
      required: false,
      default: '',
    },
    tokenScopes: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    ...mapState(useAccessTokens, [
      'busy',
      'filters',
      'page',
      'perPage',
      'showCreateForm',
      'sorting',
      'token',
      'tokens',
      'total',
      'urlParams',
    ]),
  },
  created() {
    this.setup({
      ...initializeValuesFromQuery(),
      id: this.id,
      showCreateForm: Boolean(this.tokenName || this.tokenDescription || this.tokenScopes.length),
      showCreateFormInline: true,
      urlCreate: this.accessTokenCreate,
      urlRevoke: this.accessTokenRevoke,
      urlRotate: this.accessTokenRotate,
      urlShow: this.accessTokenShow,
    });
    navigateToQuery(this.$router, this.urlParams, { replace: true });
    this.fetchTokens();
    window.addEventListener('popstate', this.handlePopState);
    // These actions change the store's filters or page; keep the address bar in sync.
    this.unsubscribeFromActions = useAccessTokens().$onAction(({ name, after }) => {
      if (['createToken', 'revokeToken', 'rotateToken'].includes(name)) {
        after(this.syncUrlWithStore);
      }
    });
  },
  beforeDestroy() {
    window.removeEventListener('popstate', this.handlePopState);
    this.unsubscribeFromActions();
  },
  methods: {
    ...mapActions(useAccessTokens, [
      'fetchTokens',
      'setFilters',
      'setPage',
      'setShowCreateForm',
      'setSorting',
      'setToken',
      'setup',
    ]),
    addAccessToken() {
      this.setToken(null);
      this.setShowCreateForm(true);
    },
    search(filters) {
      this.setFilters(filters);
      this.setPage(1);
      navigateToQuery(this.$router, this.urlParams);
      this.fetchTokens();
    },
    async pageChanged(page) {
      this.setPage(page);
      navigateToQuery(this.$router, this.urlParams);
      await this.fetchTokens();
      scrollTo({ top: 0 }, this.$el);
    },
    async handlePopState() {
      const { filters, page, sorting } = initializeValuesFromQuery();
      this.setFilters(filters);
      this.setPage(page);
      this.setSorting(sorting);
      await this.fetchTokens();
      scrollTo({ top: 0 }, this.$el);
    },
    handleSortChange(value) {
      this.setSorting({ value, isAsc: this.sorting.isAsc });
      navigateToQuery(this.$router, this.urlParams);
      this.fetchTokens();
    },
    handleSortDirectionChange(isAsc) {
      this.setSorting({ value: this.sorting.value, isAsc });
      navigateToQuery(this.$router, this.urlParams);
      this.fetchTokens();
    },
    syncUrlWithStore() {
      navigateToQuery(this.$router, this.urlParams);
    },
  },
  FILTER_OPTIONS,
  SORT_OPTIONS,
};
</script>

<template>
  <div>
    <user-avatar v-if="showAvatar" :id="id" />
    <page-heading :heading="s__('AccessTokens|Personal access tokens')">
      <template #description>
        {{
          s__(
            'AccessTokens|You can generate a personal access token for each application you use that needs access to the GitLab API. You can also use personal access tokens to authenticate against Git over HTTP. They are the only accepted password when you have Two-Factor Authentication (2FA) enabled.',
          )
        }}
      </template>
      <template #actions>
        <gl-button variant="confirm" data-testid="add-new-token-button" @click="addAccessToken">
          {{ s__('AccessTokens|Add new token') }}
        </gl-button>
      </template>
    </page-heading>
    <access-token v-if="token" />
    <access-token-form
      v-if="showCreateForm"
      :name="tokenName"
      :description="tokenDescription"
      :scopes="tokenScopes"
    />
    <access-token-statistics />
    <div class="gl-my-5 gl-flex gl-flex-col gl-gap-3 @md/panel:gl-flex-row">
      <gl-filtered-search
        class="gl-min-w-0 gl-grow"
        :value="filters"
        :placeholder="s__('AccessTokens|Search or filter access tokens…')"
        :available-tokens="$options.FILTER_OPTIONS"
        filtered-search-term-key="search"
        terms-as-tokens
        @submit="search"
      />
      <gl-sorting
        block
        dropdown-class="gl-w-full  !gl-flex"
        :is-ascending="sorting.isAsc"
        :sort-by="sorting.value"
        :sort-options="$options.SORT_OPTIONS"
        @sort-by-change="handleSortChange"
        @sort-direction-change="handleSortDirectionChange"
      />
    </div>

    <access-token-table :busy="busy" :tokens="tokens" />

    <gl-pagination
      :value="page"
      :per-page="perPage"
      :total-items="total"
      align="center"
      class="gl-mt-5"
      @input="pageChanged"
    />
  </div>
</template>
