<script>
import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import environmentAppQuery from '../graphql/queries/environment_app.query.graphql';
import pollIntervalQuery from '../graphql/queries/poll_interval.query.graphql';
import EnvironmentFolder from './new_environment_folder.vue';
import EnableReviewAppModal from './enable_review_app_modal.vue';

export default {
  components: {
    EnvironmentFolder,
    EnableReviewAppModal,
    GlBadge,
    GlTab,
    GlTabs,
  },
  apollo: {
    environmentApp: {
      query: environmentAppQuery,
      variables() {
        return {
          scope: this.scope,
        };
      },
      pollInterval() {
        return this.interval;
      },
    },
    interval: {
      query: pollIntervalQuery,
    },
  },
  inject: ['newEnvironmentPath', 'canCreateEnvironment'],
  i18n: {
    newEnvironmentButtonLabel: s__('Environments|New environment'),
    reviewAppButtonLabel: s__('Environments|Enable review app'),
    available: __('Available'),
    stopped: __('Stopped'),
  },
  modalId: 'enable-review-app-info',
  data() {
    const scope = new URLSearchParams(window.location.search).get('scope') || 'available';
    return { interval: undefined, scope, isReviewAppModalVisible: false };
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
  },
  methods: {
    showReviewAppModal() {
      this.isReviewAppModalVisible = true;
    },
    setScope(scope) {
      this.scope = scope;
      this.$apollo.queries.environmentApp.stopPolling();
      this.$nextTick(() => {
        if (this.interval) {
          this.$apollo.queries.environmentApp.startPolling(this.interval);
        } else {
          this.$apollo.queries.environmentApp.refetch({ scope });
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
  </div>
</template>
