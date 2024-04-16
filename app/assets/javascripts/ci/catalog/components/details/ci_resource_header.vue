<script>
import {
  GlAvatar,
  GlAvatarLink,
  GlBadge,
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlLink,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import { formatDate } from '~/lib/utils/datetime_utility';
import AbuseCategorySelector from '~/abuse_reports/components/abuse_category_selector.vue';
import CiVerificationBadge from '../shared/ci_verification_badge.vue';
import CiResourceAbout from './ci_resource_about.vue';
import CiResourceHeaderSkeletonLoader from './ci_resource_header_skeleton_loader.vue';

export default {
  i18n: {
    moreActionsLabel: __('More actions'),
    reportAbuse: __('Report abuse to administrator'),
    lastRelease: s__('CiCatalog|Released %{date}'),
    lastReleaseMissing: s__('CiCatalog|No release available'),
  },
  components: {
    AbuseCategorySelector,
    CiResourceAbout,
    CiResourceHeaderSkeletonLoader,
    CiVerificationBadge,
    GlAvatar,
    GlAvatarLink,
    GlBadge,
    GlDisclosureDropdown,
    GlDisclosureDropdownItem,
    GlLink,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['reportAbusePath'],
  props: {
    isLoadingDetails: {
      type: Boolean,
      required: true,
    },
    isLoadingSharedData: {
      type: Boolean,
      required: true,
    },
    openIssuesCount: {
      type: Number,
      required: false,
      default: 0,
    },
    openMergeRequestsCount: {
      type: Number,
      required: false,
      default: 0,
    },
    resource: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isReportAbuseDrawerOpen: false,
    };
  },
  computed: {
    authorId() {
      return this.hasLatestVersion && this.latestVersion?.author?.state === 'active'
        ? getIdFromGraphQLId(this.latestVersion?.author?.id)
        : 0;
    },
    entityId() {
      return getIdFromGraphQLId(this.resource.id);
    },
    hasLatestVersion() {
      return this.latestVersion?.name;
    },
    isVerified() {
      return this.resource?.verificationLevel !== 'UNVERIFIED';
    },
    lastReleaseText() {
      if (this.latestVersion?.createdAt) {
        const date = formatDate(this.latestVersion.createdAt);
        return sprintf(this.$options.i18n.lastRelease, { date });
      }

      return this.$options.i18n.lastReleaseMissing;
    },
    latestVersion() {
      return this.resource?.versions?.nodes[0] || {};
    },
    reportedFromUrl() {
      return window.location.href;
    },
    versionBadgeText() {
      return this.latestVersion.name;
    },
    webPath() {
      return cleanLeadingSeparator(this.resource?.webPath);
    },
  },
  methods: {
    onAbuseButtonClicked() {
      this.toggleReportAbuseDrawer(true);
    },
    toggleReportAbuseDrawer(isOpen) {
      this.isReportAbuseDrawerOpen = isOpen;
    },
  },
};
</script>
<template>
  <div>
    <ci-resource-header-skeleton-loader v-if="isLoadingSharedData" class="gl-py-5" />
    <div v-else class="gl-display-flex gl-justify-content-space-between gl-py-5">
      <div class="gl-display-flex">
        <gl-avatar-link :href="resource.webPath">
          <gl-avatar
            class="gl-mr-4"
            :entity-id="entityId"
            :entity-name="resource.name"
            shape="rect"
            :size="64"
            :src="resource.icon"
          />
        </gl-avatar-link>
        <div
          class="gl-display-flex gl-flex-direction-column gl-align-items-flex-start gl-justify-content-center"
        >
          <div class="gl-font-sm gl-text-secondary">
            {{ webPath }}
          </div>
          <span class="gl-display-flex">
            <gl-link
              class="gl-font-lg gl-font-weight-bold gl-text-gray-900 gl-hover-text-gray-900"
              :href="resource.webPath"
            >
              {{ resource.name }}
            </gl-link>
            <gl-badge
              v-if="hasLatestVersion"
              v-gl-tooltip
              size="sm"
              class="gl-ml-3 gl-my-1"
              :href="latestVersion.path"
              :title="lastReleaseText"
            >
              {{ versionBadgeText }}
            </gl-badge>
          </span>
          <ci-verification-badge
            v-if="isVerified"
            :verification-level="resource.verificationLevel"
            :resource-id="resource.id"
            show-text
          />
        </div>
      </div>
      <div>
        <gl-disclosure-dropdown
          v-gl-tooltip
          :title="$options.i18n.moreActionsLabel"
          :toggle-text="$options.i18n.moreActionsLabel"
          text-sr-only
          icon="ellipsis_v"
          category="tertiary"
          placement="right"
          class="note-action-button more-actions-toggle"
          no-caret
        >
          <gl-disclosure-dropdown-item
            data-testid="report-abuse-button"
            @action="onAbuseButtonClicked"
          >
            <template #list-item>
              {{ $options.i18n.reportAbuse }}
            </template>
          </gl-disclosure-dropdown-item>
        </gl-disclosure-dropdown>
      </div>
    </div>
    <ci-resource-about
      v-if="false"
      :is-loading-details="isLoadingDetails"
      :is-loading-shared-data="isLoadingSharedData"
      :open-issues-count="openIssuesCount"
      :open-merge-requests-count="openMergeRequestsCount"
      :latest-version="latestVersion"
      :web-path="resource.webPath"
    />
    <div
      v-if="isLoadingSharedData"
      class="gl-animate-skeleton-loader gl-h-4 gl-rounded-base gl-my-3 gl-max-w-20!"
    ></div>
    <p v-else class="gl-mt-2">
      {{ resource.description }}
    </p>
    <abuse-category-selector
      v-if="hasLatestVersion && isReportAbuseDrawerOpen && reportAbusePath"
      :reported-user-id="authorId"
      :reported-from-url="reportedFromUrl"
      :show-drawer="isReportAbuseDrawerOpen"
      @close-drawer="toggleReportAbuseDrawer(false)"
    />
  </div>
</template>
