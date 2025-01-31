<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlLink,
  GlModalDirective,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { isEmpty } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions } from 'vuex';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { n__, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import { buildUrlWithCurrentLocation, historyPushState } from '~/lib/utils/common_utils';
import { getParameterByName } from '~/lib/utils/url_utility';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import PromoPageLink from '~/vue_shared/components/promo_page_link/promo_page_link.vue';
import ConfigureFeatureFlagsModal from './configure_feature_flags_modal.vue';
import EmptyState from './empty_state.vue';
import FeatureFlagsTable from './feature_flags_table.vue';

export default {
  components: {
    ConfigureFeatureFlagsModal,
    EmptyState,
    FeatureFlagsTable,
    PromoPageLink,
    GlAlert,
    GlBadge,
    GlButton,
    GlLink,
    GlSprintf,
    TablePagination,
    PageHeading,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
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
      'rotateEndpoint',
    ]),
    topAreaBaseClasses() {
      return ['gl-flex', 'gl-flex-col'];
    },
    canUserRotateToken() {
      return this.rotateEndpoint !== '';
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
    isFeatureFlagsLimitSet() {
      return Boolean(Number(this.featureFlagsLimit));
    },
    countBadgeContents() {
      return this.isFeatureFlagsLimitSet ? `${this.count}/${this.featureFlagsLimit}` : this.count;
    },
    countBadgeTooltipMessage() {
      return this.isFeatureFlagsLimitSet
        ? n__(
            'FeatureFlags|Current plan allows for %d feature flag.',
            'FeatureFlags|Current plan allows for %d feature flags.',
            this.featureFlagsLimit,
          )
        : '';
    },
    limitExceededAlertMessage() {
      return s__(
        "FeatureFlags|You've reached your %{docLinkStart}feature flag limit%{docLinkEnd} (%{featureFlagsLimit}). To add more, delete at least one feature flag, or %{pricingLinkStart}upgrade to a higher tier%{pricingLinkEnd}.",
      );
    },
    documentationLink() {
      return helpPagePath('operations/feature_flags', {
        anchor: 'maximum-number-of-feature-flags',
      });
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
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="featureFlagsLimitExceeded" :dismissible="false" variant="warning">
      <gl-sprintf :message="limitExceededAlertMessage">
        <template #docLink="{ content }">
          <gl-link :href="documentationLink" target="_blank">{{ content }}</gl-link>
        </template>
        <template #featureFlagsLimit>
          <span>{{ featureFlagsLimit }}</span>
        </template>
        <template #pricingLink="{ content }">
          <promo-page-link path="/pricing" target="_blank">{{ content }}</promo-page-link>
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
      <page-heading>
        <template #heading>
          <span>
            {{ s__('FeatureFlags|Feature flags') }}
          </span>
          <gl-badge
            v-if="count"
            v-gl-tooltip="{ disabled: !isFeatureFlagsLimitSet }"
            :title="countBadgeTooltipMessage"
            class="gl-ml-3 gl-align-middle"
            >{{ countBadgeContents }}</gl-badge
          >
        </template>
        <template #actions>
          <gl-button
            v-if="userListPath"
            :href="userListPath"
            variant="confirm"
            category="tertiary"
            data-testid="ff-user-list-button"
          >
            {{ s__('FeatureFlags|View user lists') }}
          </gl-button>
          <gl-button
            v-if="canUserConfigure"
            v-gl-modal="'configure-feature-flags'"
            variant="confirm"
            category="secondary"
            data-testid="ff-configure-button"
          >
            {{ s__('FeatureFlags|Configure') }}
          </gl-button>

          <gl-button
            v-if="hasNewPath"
            :href="newFeatureFlagPath"
            :disabled="featureFlagsLimitExceeded"
            variant="confirm"
            data-testid="ff-new-button"
          >
            {{ s__('FeatureFlags|New feature flag') }}
          </gl-button></template
        >
      </page-heading>

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
        @dismissAlert="clearAlert"
      >
        <feature-flags-table :feature-flags="featureFlags" @toggle-flag="toggleFeatureFlag" />
      </empty-state>
    </div>
    <table-pagination v-if="shouldRenderPagination" :change="onChangePage" :page-info="pageInfo" />
  </div>
</template>
