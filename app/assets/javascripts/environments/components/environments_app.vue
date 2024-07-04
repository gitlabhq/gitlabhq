<script>
import { GlBadge, GlPagination, GlSearchBoxByType, GlTab, GlTabs } from '@gitlab/ui';
import { debounce } from 'lodash';
import { s__, __ } from '~/locale';
import { updateHistory, setUrlParams, queryToObject } from '~/lib/utils/url_utility';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import pageInfoQuery from '~/graphql_shared/client/page_info.query.graphql';
import environmentAppQuery from '../graphql/queries/environment_app.query.graphql';
import pollIntervalQuery from '../graphql/queries/poll_interval.query.graphql';
import environmentToDeleteQuery from '../graphql/queries/environment_to_delete.query.graphql';
import environmentToRollbackQuery from '../graphql/queries/environment_to_rollback.query.graphql';
import environmentToStopQuery from '../graphql/queries/environment_to_stop.query.graphql';
import environmentToChangeCanaryQuery from '../graphql/queries/environment_to_change_canary.query.graphql';
import { ENVIRONMENTS_SCOPE } from '../constants';
import EnvironmentFolder from './environment_folder.vue';
import EnableReviewAppModal from './enable_review_app_modal.vue';
import StopEnvironmentModal from './stop_environment_modal.vue';
import StopStaleEnvironmentsModal from './stop_stale_environments_modal.vue';
import EnvironmentItem from './new_environment_item.vue';
import ConfirmRollbackModal from './confirm_rollback_modal.vue';
import DeleteEnvironmentModal from './delete_environment_modal.vue';
import CanaryUpdateModal from './canary_update_modal.vue';
import EmptyState from './empty_state.vue';
import EnviromentsAppSkeletonLoader from './environments_app_skeleton_loader.vue';

export default {
  components: {
    DeleteEnvironmentModal,
    CanaryUpdateModal,
    ConfirmRollbackModal,
    EmptyState,
    EnviromentsAppSkeletonLoader,
    EnvironmentFolder,
    EnableReviewAppModal,
    EnvironmentItem,
    StopEnvironmentModal,
    StopStaleEnvironmentsModal,
    GlBadge,
    GlPagination,
    GlSearchBoxByType,
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
          search: this.search,
        };
      },
      pollInterval: 3000,
    },
    interval: {
      query: pollIntervalQuery,
    },
    pageInfo: {
      query: pageInfoQuery,
      variables() {
        return { page: this.page };
      },
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
    reviewAppButtonLabel: s__('Environments|Enable review apps'),
    cleanUpEnvsButtonLabel: s__('Environments|Clean up environments'),
    active: __('Active'),
    stopped: __('Stopped'),
    prevPage: __('Go to previous page'),
    nextPage: __('Go to next page'),
    next: __('Next'),
    prev: __('Prev'),
    searchPlaceholder: s__('Environments|Search by environment name'),
  },
  modalId: 'enable-review-app-info',
  stopStaleEnvsModalId: 'stop-stale-environments-modal',
  data() {
    const { page = '1', search = '', scope } = queryToObject(window.location.search);
    return {
      interval: undefined,
      isReviewAppModalVisible: false,
      isStopStaleEnvModalVisible: false,
      page: parseInt(page, 10),
      pageInfo: {},
      scope: Object.values(ENVIRONMENTS_SCOPE).includes(scope) ? scope : ENVIRONMENTS_SCOPE.ACTIVE,
      environmentToDelete: {},
      environmentToRollback: {},
      environmentToStop: {},
      environmentToChangeCanary: {},
      weight: 0,
      search,
    };
  },
  computed: {
    canSetupReviewApp() {
      return this.environmentApp?.reviewApp?.canSetupReviewApp;
    },
    hasReviewApp() {
      return this.environmentApp?.reviewApp?.hasReviewApp;
    },
    canCleanUpEnvs() {
      return this.environmentApp?.canStopStaleEnvironments;
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
    loading() {
      return this.$apollo.queries.environmentApp.loading;
    },
    showEmptyState() {
      return !this.$apollo.queries.environmentApp.loading && !this.hasEnvironments;
    },
    hasSearch() {
      return Boolean(this.search);
    },
    activeCount() {
      return this.environmentApp?.activeCount ?? 0;
    },
    stoppedCount() {
      return this.environmentApp?.stoppedCount ?? 0;
    },
    hasAnyEnvironment() {
      return this.activeCount > 0 || this.stoppedCount > 0;
    },
    showContent() {
      return !this.loading && (this.hasAnyEnvironment || this.hasSearch);
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
      // we don't show the Enable review apps button
      // if a user cannot setup a review app or review
      // apps are already configured
      if (!this.canSetupReviewApp || this.hasReviewApp) {
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
    openCleanUpEnvsModal() {
      if (!this.canCleanUpEnvs) {
        return null;
      }

      return {
        text: this.$options.i18n.cleanUpEnvsButtonLabel,
        attributes: {
          category: 'secondary',
          variant: 'confirm',
        },
      };
    },
    totalItems() {
      return this.pageInfo?.total;
    },
    itemsPerPage() {
      return this.pageInfo?.perPage;
    },
  },
  watch: {
    interval(val) {
      this.$apollo.queries.environmentApp.stopPolling();
      this.$apollo.queries.environmentApp.startPolling(val);
    },
  },
  mounted() {
    window.addEventListener('popstate', this.syncPageFromQueryParams);
    window.addEventListener('popstate', this.syncSearchFromQueryParams);
  },
  destroyed() {
    window.removeEventListener('popstate', this.syncPageFromQueryParams);
    window.removeEventListener('popstate', this.syncSearchFromQueryParams);
    this.$apollo.queries.environmentApp.stopPolling();
  },
  methods: {
    showReviewAppModal() {
      this.isReviewAppModalVisible = true;
    },
    showCleanUpEnvsModal() {
      this.isStopStaleEnvModalVisible = true;
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
        url: setUrlParams({ page: this.page, scope: this.scope, search: this.search }),
        title: document.title,
      });
    },
    setSearch: debounce(function setSearch(input) {
      this.search = input;
      this.moveToPage(1);
    }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS),
    syncPageFromQueryParams() {
      const { page = '1' } = queryToObject(window.location.search);
      this.page = parseInt(page, 10);
    },
    syncSearchFromQueryParams() {
      const { search = '' } = queryToObject(window.location.search);
      this.search = search;
    },
    refetchEnvironments() {
      this.$apollo.queries.environmentApp.refetch();
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
    />
    <stop-stale-environments-modal
      v-if="canCleanUpEnvs"
      v-model="isStopStaleEnvModalVisible"
      :modal-id="$options.stopStaleEnvsModalId"
      data-testid="stop-stale-environments-modal"
    />
    <delete-environment-modal :environment="environmentToDelete" graphql />
    <stop-environment-modal :environment="environmentToStop" graphql />
    <confirm-rollback-modal :environment="environmentToRollback" graphql />
    <canary-update-modal :environment="environmentToChangeCanary" :weight="weight" />
    <enviroments-app-skeleton-loader v-if="loading" :i18n="$options.i18n" :search-value="search" />
    <template v-if="showContent">
      <gl-tabs
        :action-secondary="openReviewAppModal"
        :action-primary="openCleanUpEnvsModal"
        :action-tertiary="addEnvironment"
        sync-active-tab-with-query-params
        query-param-name="scope"
        @secondary="showReviewAppModal"
        @primary="showCleanUpEnvsModal"
      >
        <gl-tab
          :query-param-value="$options.ENVIRONMENTS_SCOPE.ACTIVE"
          @click="setScope($options.ENVIRONMENTS_SCOPE.ACTIVE)"
        >
          <template #title>
            <span>{{ $options.i18n.active }}</span>
            <gl-badge class="gl-tab-counter-badge">
              {{ activeCount }}
            </gl-badge>
          </template>
        </gl-tab>
        <gl-tab
          :query-param-value="$options.ENVIRONMENTS_SCOPE.STOPPED"
          @click="setScope($options.ENVIRONMENTS_SCOPE.STOPPED)"
        >
          <template #title>
            <span>{{ $options.i18n.stopped }}</span>
            <gl-badge class="gl-tab-counter-badge">
              {{ stoppedCount }}
            </gl-badge>
          </template>
        </gl-tab>
      </gl-tabs>
      <gl-search-box-by-type
        class="gl-mb-4"
        :value="search"
        :placeholder="$options.i18n.searchPlaceholder"
        @input="setSearch"
      />
      <environment-folder
        v-for="folder in folders"
        :key="folder.name"
        class="gl-mb-3"
        :scope="scope"
        :search="search"
        :nested-environment="folder"
      />
      <environment-item
        v-for="environment in environments"
        :key="environment.name"
        class="gl-mb-3 gl-border-gray-100 gl-border-1 gl-border-b-solid"
        :environment="environment.latest"
        @change="refetchEnvironments"
      />
    </template>
    <empty-state
      v-if="showEmptyState"
      :help-path="helpPagePath"
      :has-term="hasSearch"
      @enable-review="showReviewAppModal"
    />
    <gl-pagination
      align="center"
      :total-items="totalItems"
      :per-page="itemsPerPage"
      :value="page"
      :next="$options.i18n.next"
      :prev="$options.i18n.prev"
      :label-previous-page="$options.prevPage"
      :label-next-page="$options.nextPage"
      @next="movePage('next')"
      @previous="movePage('previous')"
      @input="moveToPage"
    />
  </div>
</template>
