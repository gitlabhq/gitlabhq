<script>
import { GlBadge, GlPagination, GlTab, GlTabs } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { updateHistory, setUrlParams, queryToObject } from '~/lib/utils/url_utility';
import environmentAppQuery from '../graphql/queries/environment_app.query.graphql';
import pollIntervalQuery from '../graphql/queries/poll_interval.query.graphql';
import pageInfoQuery from '../graphql/queries/page_info.query.graphql';
import environmentToDeleteQuery from '../graphql/queries/environment_to_delete.query.graphql';
import environmentToRollbackQuery from '../graphql/queries/environment_to_rollback.query.graphql';
import environmentToStopQuery from '../graphql/queries/environment_to_stop.query.graphql';
import environmentToChangeCanaryQuery from '../graphql/queries/environment_to_change_canary.query.graphql';
import { ENVIRONMENTS_SCOPE } from '../constants';
import EnvironmentFolder from './environment_folder.vue';
import EnableReviewAppModal from './enable_review_app_modal.vue';
import StopEnvironmentModal from './stop_environment_modal.vue';
import EnvironmentItem from './new_environment_item.vue';
import ConfirmRollbackModal from './confirm_rollback_modal.vue';
import DeleteEnvironmentModal from './delete_environment_modal.vue';
import CanaryUpdateModal from './canary_update_modal.vue';
import EmptyState from './empty_state.vue';

export default {
  components: {
    DeleteEnvironmentModal,
    CanaryUpdateModal,
    ConfirmRollbackModal,
    EmptyState,
    EnvironmentFolder,
    EnableReviewAppModal,
    EnvironmentItem,
    StopEnvironmentModal,
    GlBadge,
    GlPagination,
    GlTab,
    GlTabs,
  },
  apollo: {
    environmentApp: {
      query: environmentAppQuery,
      variables() {
        return {
          scope: this.scope,
          page: this.page ?? 1,
        };
      },
      pollInterval() {
        return this.interval;
      },
    },
    interval: {
      query: pollIntervalQuery,
    },
    pageInfo: {
      query: pageInfoQuery,
    },
    environmentToDelete: {
      query: environmentToDeleteQuery,
    },
    environmentToRollback: {
      query: environmentToRollbackQuery,
    },
    environmentToStop: {
      query: environmentToStopQuery,
    },
    environmentToChangeCanary: {
      query: environmentToChangeCanaryQuery,
    },
    weight: {
      query: environmentToChangeCanaryQuery,
    },
  },
  inject: ['newEnvironmentPath', 'canCreateEnvironment', 'helpPagePath'],
  i18n: {
    newEnvironmentButtonLabel: s__('Environments|New environment'),
    reviewAppButtonLabel: s__('Environments|Enable review app'),
    available: __('Available'),
    stopped: __('Stopped'),
    prevPage: __('Go to previous page'),
    nextPage: __('Go to next page'),
    next: __('Next'),
    prev: __('Prev'),
    goto: (page) => sprintf(__('Go to page %{page}'), { page }),
  },
  modalId: 'enable-review-app-info',
  data() {
    const { page = '1', scope } = queryToObject(window.location.search);
    return {
      interval: undefined,
      isReviewAppModalVisible: false,
      page: parseInt(page, 10),
      pageInfo: {},
      scope: Object.values(ENVIRONMENTS_SCOPE).includes(scope)
        ? scope
        : ENVIRONMENTS_SCOPE.AVAILABLE,
      environmentToDelete: {},
      environmentToRollback: {},
      environmentToStop: {},
      environmentToChangeCanary: {},
      weight: 0,
    };
  },
  computed: {
    canSetupReviewApp() {
      return this.environmentApp?.reviewApp?.canSetupReviewApp;
    },
    folders() {
      return this.environmentApp?.environments?.filter((e) => e.size > 1) ?? [];
    },
    environments() {
      return this.environmentApp?.environments?.filter((e) => e.size === 1) ?? [];
    },
    hasEnvironments() {
      return this.environments.length > 0 || this.folders.length > 0;
    },
    availableCount() {
      return this.environmentApp?.availableCount;
    },
    addEnvironment() {
      if (!this.canCreateEnvironment) {
        return null;
      }

      return {
        text: this.$options.i18n.newEnvironmentButtonLabel,
        attributes: {
          href: this.newEnvironmentPath,
          category: 'primary',
          variant: 'confirm',
        },
      };
    },
    openReviewAppModal() {
      if (!this.canSetupReviewApp) {
        return null;
      }

      return {
        text: this.$options.i18n.reviewAppButtonLabel,
        attributes: {
          category: 'secondary',
          variant: 'confirm',
        },
      };
    },
    stoppedCount() {
      return this.environmentApp?.stoppedCount;
    },
    totalItems() {
      return this.pageInfo?.total;
    },
    itemsPerPage() {
      return this.pageInfo?.perPage;
    },
  },
  mounted() {
    window.addEventListener('popstate', this.syncPageFromQueryParams);
  },
  destroyed() {
    window.removeEventListener('popstate', this.syncPageFromQueryParams);
    this.$apollo.queries.environmentApp.stopPolling();
  },
  methods: {
    showReviewAppModal() {
      this.isReviewAppModalVisible = true;
    },
    setScope(scope) {
      this.scope = scope;
      this.moveToPage(1);
    },
    movePage(direction) {
      this.moveToPage(this.pageInfo[`${direction}Page`]);
    },
    moveToPage(page) {
      this.page = page;
      updateHistory({
        url: setUrlParams({ page: this.page }),
        title: document.title,
      });
      this.resetPolling();
    },
    syncPageFromQueryParams() {
      const { page = '1' } = queryToObject(window.location.search);
      this.page = parseInt(page, 10);
    },
    resetPolling() {
      this.$apollo.queries.environmentApp.stopPolling();
      this.$apollo.queries.environmentApp.refetch();
      this.$nextTick(() => {
        if (this.interval) {
          this.$apollo.queries.environmentApp.startPolling(this.interval);
        }
      });
    },
  },
  ENVIRONMENTS_SCOPE,
};
</script>
<template>
  <div>
    <enable-review-app-modal
      v-if="canSetupReviewApp"
      v-model="isReviewAppModalVisible"
      :modal-id="$options.modalId"
      data-testid="enable-review-app-modal"
    />
    <delete-environment-modal :environment="environmentToDelete" graphql />
    <stop-environment-modal :environment="environmentToStop" graphql />
    <confirm-rollback-modal :environment="environmentToRollback" graphql />
    <canary-update-modal :environment="environmentToChangeCanary" :weight="weight" />
    <gl-tabs
      :action-secondary="addEnvironment"
      :action-primary="openReviewAppModal"
      sync-active-tab-with-query-params
      query-param-name="scope"
      @primary="showReviewAppModal"
    >
      <gl-tab
        :query-param-value="$options.ENVIRONMENTS_SCOPE.AVAILABLE"
        @click="setScope($options.ENVIRONMENTS_SCOPE.AVAILABLE)"
      >
        <template #title>
          <span>{{ $options.i18n.available }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">
            {{ availableCount }}
          </gl-badge>
        </template>
      </gl-tab>
      <gl-tab
        :query-param-value="$options.ENVIRONMENTS_SCOPE.STOPPED"
        @click="setScope($options.ENVIRONMENTS_SCOPE.STOPPED)"
      >
        <template #title>
          <span>{{ $options.i18n.stopped }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">
            {{ stoppedCount }}
          </gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
    <template v-if="hasEnvironments">
      <environment-folder
        v-for="folder in folders"
        :key="folder.name"
        class="gl-mb-3"
        :scope="scope"
        :nested-environment="folder"
      />
      <environment-item
        v-for="environment in environments"
        :key="environment.name"
        class="gl-mb-3 gl-border-gray-100 gl-border-1 gl-border-b-solid"
        :environment="environment.latest"
        @change="resetPolling"
      />
    </template>
    <empty-state v-else :help-path="helpPagePath" />
    <gl-pagination
      align="center"
      :total-items="totalItems"
      :per-page="itemsPerPage"
      :value="page"
      :next="$options.i18n.next"
      :prev="$options.i18n.prev"
      :label-previous-page="$options.prevPage"
      :label-next-page="$options.nextPage"
      :label-page="$options.goto"
      @next="movePage('next')"
      @previous="movePage('previous')"
      @input="moveToPage"
    />
  </div>
</template>
