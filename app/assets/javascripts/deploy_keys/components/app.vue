<script>
import { GlButton, GlIcon, GlLoadingIcon, GlPagination } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { s__, __, sprintf } from '~/locale';
import { captureException } from '~/sentry/sentry_browser_wrapper';
import pageInfoQuery from '~/graphql_shared/client/page_info.query.graphql';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
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

export default {
  components: {
    ConfirmModal,
    KeysPanel,
    NavigationTabs,
    GlButton,
    GlIcon,
    GlLoadingIcon,
    GlPagination,
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
        };
      },
      update(data) {
        return data?.project?.deployKeys || [];
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
        return { input: { page: this.currentPage, scope: this.currentScope } };
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
      deployKeyToRemove: null,
    };
  },
  scopes: {
    enabledKeys: s__('DeployKeys|Enabled deploy keys'),
    availableProjectKeys: s__('DeployKeys|Privately accessible deploy keys'),
    availablePublicKeys: s__('DeployKeys|Publicly accessible deploy keys'),
  },
  i18n: {
    loading: s__('DeployKeys|Loading deploy keys'),
    addButton: s__('DeployKeys|Add new key'),
    prevPage: __('Go to previous page'),
    nextPage: __('Go to next page'),
    next: __('Next'),
    prev: __('Prev'),
    goto: (page) => sprintf(__('Go to page %{page}'), { page }),
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
  },
  methods: {
    onChangeTab(scope) {
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
  },
};
</script>

<template>
  <div class="deploy-keys">
    <confirm-modal :visible="confirmModalVisible" @remove="removeKey" @cancel="cancel" />
    <div class="gl-new-card-header gl-align-items-center gl-py-0 gl-pl-0">
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

      <div class="gl-new-card-actions">
        <gl-button
          size="small"
          class="js-toggle-button js-toggle-content"
          data-testid="add-new-deploy-key-button"
        >
          {{ $options.i18n.addButton }}
        </gl-button>
      </div>
    </div>
    <gl-loading-icon
      v-if="$apollo.queries.deployKeys.loading"
      :label="$options.i18n.loading"
      size="md"
      class="gl-m-5"
    />
    <template v-else>
      <keys-panel
        :project-id="projectId"
        :keys="deployKeys"
        data-testid="project-deploy-keys-container"
      />
      <gl-pagination
        align="center"
        :total-items="pageInfo.total"
        :per-page="pageInfo.perPage"
        :value="currentPage"
        :next="$options.i18n.next"
        :prev="$options.i18n.prev"
        :label-previous-page="$options.i18n.prevPage"
        :label-next-page="$options.i18n.nextPage"
        :label-page="$options.i18n.goto"
        @next="moveNext()"
        @previous="movePrevious()"
        @input="moveToPage"
      />
    </template>
  </div>
</template>
