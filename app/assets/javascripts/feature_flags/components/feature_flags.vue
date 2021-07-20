<script>
import { GlAlert, GlBadge, GlButton, GlModalDirective, GlSprintf } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapState, mapActions } from 'vuex';

import { buildUrlWithCurrentLocation, historyPushState } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import ConfigureFeatureFlagsModal from './configure_feature_flags_modal.vue';
import EmptyState from './empty_state.vue';
import FeatureFlagsTable from './feature_flags_table.vue';

export default {
  components: {
    ConfigureFeatureFlagsModal,
    EmptyState,
    FeatureFlagsTable,
    GlAlert,
    GlBadge,
    GlButton,
    GlSprintf,
    TablePagination,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  inject: {
    userListPath: { default: '' },
    newFeatureFlagPath: { default: '' },
    canUserConfigure: {},
    featureFlagsLimitExceeded: {},
    featureFlagsLimit: {},
  },
  data() {
    return {
      page: getParameterByName('page') || '1',
      shouldShowFeatureFlagsLimitWarning: this.featureFlagsLimitExceeded,
    };
  },
  computed: {
    ...mapState([
      'featureFlags',
      'alerts',
      'count',
      'pageInfo',
      'isLoading',
      'hasError',
      'options',
      'instanceId',
      'isRotating',
      'hasRotateError',
    ]),
    topAreaBaseClasses() {
      return ['gl-display-flex', 'gl-flex-direction-column'];
    },
    canUserRotateToken() {
      return this.rotateInstanceIdPath !== '';
    },
    shouldRenderPagination() {
      return (
        !this.isLoading &&
        !this.hasError &&
        this.featureFlags.length > 0 &&
        this.pageInfo.total > this.pageInfo.perPage
      );
    },
    shouldShowEmptyState() {
      return !this.isLoading && !this.hasError && this.featureFlags.length === 0;
    },
    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
    },
    shouldRenderFeatureFlags() {
      return !this.isLoading && this.featureFlags.length > 0 && !this.hasError;
    },
    hasNewPath() {
      return !isEmpty(this.newFeatureFlagPath);
    },
  },
  created() {
    this.setFeatureFlagsOptions({ page: this.page });
    this.fetchFeatureFlags();
  },
  methods: {
    ...mapActions([
      'setFeatureFlagsOptions',
      'fetchFeatureFlags',
      'rotateInstanceId',
      'toggleFeatureFlag',
      'clearAlert',
    ]),
    onChangePage(page) {
      this.updateFeatureFlagOptions({
        /* URLS parameters are strings, we need to parse to match types */
        page: Number(page).toString(),
      });
    },
    updateFeatureFlagOptions(parameters) {
      const queryString = Object.keys(parameters)
        .map((parameter) => {
          const value = parameters[parameter];
          return `${parameter}=${encodeURIComponent(value)}`;
        })
        .join('&');

      historyPushState(buildUrlWithCurrentLocation(`?${queryString}`));
      this.setFeatureFlagsOptions(parameters);
      this.fetchFeatureFlags();
    },
    onDismissFeatureFlagsLimitWarning() {
      this.shouldShowFeatureFlagsLimitWarning = false;
    },
    onNewFeatureFlagCLick() {
      if (this.featureFlagsLimitExceeded) {
        this.shouldShowFeatureFlagsLimitWarning = true;
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-alert
      v-if="shouldShowFeatureFlagsLimitWarning"
      variant="warning"
      @dismiss="onDismissFeatureFlagsLimitWarning"
    >
      <gl-sprintf
        :message="
          s__(
            'FeatureFlags|Feature flags limit reached (%{featureFlagsLimit}). Delete one or more feature flags before adding new ones.',
          )
        "
      >
        <template #featureFlagsLimit>
          <span>{{ featureFlagsLimit }}</span>
        </template>
      </gl-sprintf>
    </gl-alert>
    <configure-feature-flags-modal
      v-if="canUserConfigure"
      :instance-id="instanceId"
      :is-rotating="isRotating"
      :has-rotate-error="hasRotateError"
      :can-user-rotate-token="canUserRotateToken"
      modal-id="configure-feature-flags"
      @token="rotateInstanceId()"
    />
    <div :class="topAreaBaseClasses">
      <div class="gl-display-flex gl-flex-direction-column gl-md-display-none!">
        <gl-button
          v-if="userListPath"
          :href="userListPath"
          variant="confirm"
          category="tertiary"
          class="gl-mb-3"
          data-testid="ff-new-list-button"
        >
          {{ s__('FeatureFlags|View user lists') }}
        </gl-button>
        <gl-button
          v-if="canUserConfigure"
          v-gl-modal="'configure-feature-flags'"
          variant="info"
          category="secondary"
          data-qa-selector="configure_feature_flags_button"
          data-testid="ff-configure-button"
          class="gl-mb-3"
        >
          {{ s__('FeatureFlags|Configure') }}
        </gl-button>

        <gl-button
          v-if="hasNewPath"
          :href="featureFlagsLimitExceeded ? '' : newFeatureFlagPath"
          variant="confirm"
          data-testid="ff-new-button"
          @click="onNewFeatureFlagCLick"
        >
          {{ s__('FeatureFlags|New feature flag') }}
        </gl-button>
      </div>
      <div
        class="gl-display-flex gl-align-items-baseline gl-flex-direction-row gl-justify-content-space-between gl-mt-6"
      >
        <div class="gl-display-flex gl-align-items-center">
          <h2 data-testid="feature-flags-tab-title" class="gl-font-size-h2 gl-my-0">
            {{ s__('FeatureFlags|Feature Flags') }}
          </h2>
          <gl-badge v-if="count" class="gl-ml-4">{{ count }}</gl-badge>
        </div>
        <div
          class="gl-display-none gl-md-display-flex gl-align-items-center gl-justify-content-end"
        >
          <gl-button
            v-if="userListPath"
            :href="userListPath"
            variant="confirm"
            category="tertiary"
            class="gl-mb-0 gl-mr-4"
            data-testid="ff-user-list-button"
          >
            {{ s__('FeatureFlags|View user lists') }}
          </gl-button>
          <gl-button
            v-if="canUserConfigure"
            v-gl-modal="'configure-feature-flags'"
            variant="info"
            category="secondary"
            data-qa-selector="configure_feature_flags_button"
            data-testid="ff-configure-button"
            class="gl-mb-0 gl-mr-4"
          >
            {{ s__('FeatureFlags|Configure') }}
          </gl-button>

          <gl-button
            v-if="hasNewPath"
            :href="featureFlagsLimitExceeded ? '' : newFeatureFlagPath"
            variant="confirm"
            data-testid="ff-new-button"
            @click="onNewFeatureFlagCLick"
          >
            {{ s__('FeatureFlags|New feature flag') }}
          </gl-button>
        </div>
      </div>
      <empty-state
        :alerts="alerts"
        :is-loading="isLoading"
        :loading-label="s__('FeatureFlags|Loading feature flags')"
        :error-state="shouldRenderErrorState"
        :error-title="s__(`FeatureFlags|There was an error fetching the feature flags.`)"
        :empty-state="shouldShowEmptyState"
        :empty-title="s__('FeatureFlags|Get started with feature flags')"
        :empty-description="
          s__(
            'FeatureFlags|Feature flags allow you to configure your code into different flavors by dynamically toggling certain functionality.',
          )
        "
        data-testid="feature-flags-tab"
        @dismissAlert="clearAlert"
      >
        <feature-flags-table :feature-flags="featureFlags" @toggle-flag="toggleFeatureFlag" />
      </empty-state>
    </div>
    <table-pagination v-if="shouldRenderPagination" :change="onChangePage" :page-info="pageInfo" />
  </div>
</template>
