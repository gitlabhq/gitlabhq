<script>
import {
  GlIcon,
  GlLoadingIcon,
  GlPagination,
  GlFilteredSearch,
  GlFilteredSearchToken,
} from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__ } from '~/locale';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import pageInfoQuery from '~/graphql_shared/client/page_info.query.graphql';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import deployKeysQuery from '../graphql/queries/deploy_keys.query.graphql';
import currentPageQuery from '../graphql/queries/current_page.query.graphql';
import currentScopeQuery from '../graphql/queries/current_scope.query.graphql';
import confirmRemoveKeyQuery from '../graphql/queries/confirm_remove_key.query.graphql';
import updateCurrentScopeMutation from '../graphql/mutations/update_current_scope.mutation.graphql';
import updateCurrentPageMutation from '../graphql/mutations/update_current_page.mutation.graphql';
import confirmDisableMutation from '../graphql/mutations/confirm_action.mutation.graphql';
import disableKeyMutation from '../graphql/mutations/disable_key.mutation.graphql';
import ConfirmModal from './confirm_modal.vue';
import KeysPanel from './keys_panel.vue';

const titleToken = {
  title: s__('DeployKeys|Name'),
  type: 'title',
  operators: OPERATORS_IS,
  token: GlFilteredSearchToken,
  unique: true,
};
const keyToken = {
  title: s__('DeployKeys|SHA'),
  type: 'key',
  operators: OPERATORS_IS,
  token: GlFilteredSearchToken,
  unique: true,
};

export default {
  components: {
    ConfirmModal,
    KeysPanel,
    NavigationTabs,
    GlIcon,
    GlLoadingIcon,
    GlPagination,
    GlFilteredSearch,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: true,
    },
  },
  apollo: {
    deployKeys: {
      query: deployKeysQuery,
      variables() {
        return {
          projectPath: this.projectPath,
          scope: this.currentScope,
          page: this.currentPage,
          search: this.searchObject,
        };
      },
      update(data) {
        return data?.project?.deployKeys || [];
      },
      skip() {
        return !this.currentPage || !this.currentScope;
      },
      error(error) {
        createAlert({
          message: s__('DeployKeys|Error getting deploy keys'),
          captureError: true,
          error,
        });
      },
    },
    pageInfo: {
      query: pageInfoQuery,
      variables() {
        return {
          input: { page: this.currentPage, scope: this.currentScope, search: this.searchObject },
        };
      },
      update({ pageInfo }) {
        return pageInfo || {};
      },
    },
    currentPage: {
      query: currentPageQuery,
    },
    currentScope: {
      query: currentScopeQuery,
    },
    deployKeyToRemove: {
      query: confirmRemoveKeyQuery,
    },
  },
  data() {
    return {
      deployKeys: [],
      pageInfo: {},
      currentPage: null,
      currentScope: null,
      deployKeyToRemove: null,
      searchObject: null,
      searchValue: [],
      availableTokens: [titleToken, keyToken],
    };
  },
  scopes: {
    enabledKeys: s__('DeployKeys|Enabled deploy keys'),
    availableProjectKeys: s__('DeployKeys|Privately accessible deploy keys'),
    availablePublicKeys: s__('DeployKeys|Publicly accessible deploy keys'),
  },
  i18n: {
    loading: s__('DeployKeys|Loading deploy keys'),
  },
  computed: {
    tabs() {
      return Object.entries(this.$options.scopes).map(([scope, name]) => {
        return {
          name,
          scope,
          isActive: scope === this.currentScope,
        };
      });
    },
    confirmModalVisible() {
      return Boolean(this.deployKeyToRemove);
    },
    hasSearch() {
      return Boolean(this.searchObject?.search);
    },
    loading() {
      return this.$apollo.queries.deployKeys.loading;
    },
  },
  methods: {
    onChangeTab(scope) {
      this.searchObject = null;
      this.searchValue = [];

      return this.$apollo
        .mutate({
          mutation: updateCurrentScopeMutation,
          variables: { scope },
        })
        .then(() => {
          this.$apollo.queries.deployKeys.refetch();
        })
        .catch((error) => {
          captureException(error, {
            tags: {
              deployKeyScope: scope,
            },
          });
        });
    },
    moveNext() {
      return this.movePage('next');
    },
    movePrevious() {
      return this.movePage('previous');
    },
    movePage(direction) {
      return this.moveToPage(this.pageInfo[`${direction}Page`]);
    },
    moveToPage(page) {
      return this.$apollo.mutate({ mutation: updateCurrentPageMutation, variables: { page } });
    },
    removeKey() {
      this.$apollo
        .mutate({
          mutation: disableKeyMutation,
          variables: { id: this.deployKeyToRemove.id },
        })
        .then(() => {
          if (!this.deployKeys.length) {
            return this.movePage('previous');
          }
          return null;
        })
        .then(() => this.$apollo.queries.deployKeys.refetch())
        .catch(() => {
          createAlert({
            message: s__('DeployKeys|Error removing deploy key'),
          });
        });
    },
    cancel() {
      this.$apollo.mutate({
        mutation: confirmDisableMutation,
        variables: { id: null },
      });
    },
    updateSearch(search = []) {
      const currentSearch = search[0];
      const defaultTokens = [titleToken, keyToken];

      if (!currentSearch?.value?.data) {
        this.availableTokens = defaultTokens;
        return;
      }

      const tokenTypeMap = {
        title: [titleToken],
        key: [keyToken],
      };
      this.availableTokens = tokenTypeMap[currentSearch.type] || [];
    },
    handleSearch(search = []) {
      if (!search.length) {
        this.searchObject = null;
        return;
      }

      const currentSearch = search[0];
      this.searchObject = this.buildSearchObject(currentSearch);
    },
    buildSearchObject(searchItem) {
      if (typeof searchItem === 'string') {
        return {
          search: searchItem,
          in: '',
        };
      }

      return {
        search: searchItem.value?.data,
        in: searchItem.type,
      };
    },
  },
};
</script>

<template>
  <div class="deploy-keys">
    <confirm-modal :visible="confirmModalVisible" @remove="removeKey" @cancel="cancel" />
    <div class="gl-items-center gl-py-0 gl-pl-0">
      <div class="top-area scrolling-tabs-container inner-page-scroll-tabs gl-border-b-0">
        <div class="fade-left">
          <gl-icon name="chevron-lg-left" :size="12" />
        </div>
        <div class="fade-right">
          <gl-icon name="chevron-lg-right" :size="12" />
        </div>

        <navigation-tabs
          :tabs="tabs"
          scope="deployKeys"
          class="gl-rounded-lg"
          @onChangeTab="onChangeTab"
        />
      </div>
    </div>

    <div class="gl-mt-4 gl-px-4">
      <gl-filtered-search
        v-model="searchValue"
        :placeholder="__('Search deploy keys')"
        :available-tokens="availableTokens"
        :view-only="loading"
        @clear="handleSearch"
        @input="updateSearch"
        @submit="handleSearch"
      />
    </div>
    <gl-loading-icon v-if="loading" :label="$options.i18n.loading" size="md" class="gl-m-5" />

    <template v-else>
      <keys-panel
        :project-id="projectId"
        :keys="deployKeys"
        :has-search="hasSearch"
        data-testid="project-deploy-keys-container"
      />
      <gl-pagination
        align="center"
        :total-items="pageInfo.total"
        :per-page="pageInfo.perPage"
        :value="currentPage"
        @next="moveNext()"
        @previous="movePrevious()"
        @input="moveToPage"
      />
    </template>
  </div>
</template>
