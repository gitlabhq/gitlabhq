<script>
import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import { s__ } from '~/locale';
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
  },
  modalId: 'enable-review-app-info',
  data() {
    return { interval: undefined, isReviewAppModalVisible: false };
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
  },
  methods: {
    showReviewAppModal() {
      this.isReviewAppModalVisible = true;
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
      @primary="showReviewAppModal"
    >
      <gl-tab>
        <template #title>
          <span>{{ __('Available') }}</span>
          <gl-badge size="sm" class="gl-tab-counter-badge">
            {{ availableCount }}
          </gl-badge>
        </template>
        <environment-folder
          v-for="folder in folders"
          :key="folder.name"
          class="gl-mb-3"
          :nested-environment="folder"
        />
      </gl-tab>
    </gl-tabs>
  </div>
</template>
