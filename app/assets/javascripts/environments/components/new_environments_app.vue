<script>
import { GlBadge, GlPagination, GlTab, GlTabs } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import { updateHistory, setUrlParams, queryToObject } from '~/lib/utils/url_utility';
import environmentAppQuery from '../graphql/queries/environment_app.query.graphql';
import pollIntervalQuery from '../graphql/queries/poll_interval.query.graphql';
import pageInfoQuery from '../graphql/queries/page_info.query.graphql';
import environmentToStopQuery from '../graphql/queries/environment_to_stop.query.graphql';
import EnvironmentFolder from './new_environment_folder.vue';
import EnableReviewAppModal from './enable_review_app_modal.vue';
import StopEnvironmentModal from './stop_environment_modal.vue';

export default {
  components: {
    EnvironmentFolder,
    EnableReviewAppModal,
    GlBadge,
    GlPagination,
    GlTab,
    GlTabs,
    StopEnvironmentModal,
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
    environmentToStop: {
      query: environmentToStopQuery,
    },
  },
  inject: ['newEnvironmentPath', 'canCreateEnvironment'],
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
    const { page = '1', scope = 'available' } = queryToObject(window.location.search);
    return {
      interval: undefined,
      isReviewAppModalVisible: false,
      page: parseInt(page, 10),
      scope,
      environmentToStop: {},
    };
  },
  computed: {
    canSetupReviewApp() {
      return this.environmentApp?.reviewApp?.canSetupReviewApp;
    },
    folders() {
      return this.environmentApp?.environments.filter((e) => e.size > 1) ?? [];
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
      this.resetPolling();
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
      this.$nextTick(() => {
        if (this.interval) {
          this.$apollo.queries.environmentApp.startPolling(this.interval);
        } else {
          this.$apollo.queries.environmentApp.refetch({ scope: this.scope, page: this.page });
        }
      });
    },
  },
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
    <stop-environment-modal :environment="environmentToStop" graphql />
    <gl-tabs
      :action-secondary="addEnvironment"
      :action-primary="openReviewAppModal"
      sync-active-tab-with-query-params
      query-param-name="scope"
      @primary="showReviewAppModal"
    >
      <gl-tab query-param-value="available" @click="setScope('available')">
        <template #title>
          <span>{{ $options.i18n.available }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">
            {{ availableCount }}
          </gl-badge>
        </template>
      </gl-tab>
      <gl-tab query-param-value="stopped" @click="setScope('stopped')">
        <template #title>
          <span>{{ $options.i18n.stopped }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">
            {{ stoppedCount }}
          </gl-badge>
        </template>
      </gl-tab>
    </gl-tabs>
    <environment-folder
      v-for="folder in folders"
      :key="folder.name"
      class="gl-mb-3"
      :nested-environment="folder"
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
      :label-page="$options.goto"
      @next="movePage('next')"
      @previous="movePage('previous')"
      @input="moveToPage"
    />
  </div>
</template>
