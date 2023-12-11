<script>
import { GlAvatar, GlAvatarLink, GlBadge } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { cleanLeadingSeparator } from '~/lib/utils/url_utility';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import CiResourceAbout from './ci_resource_about.vue';
import CiResourceHeaderSkeletonLoader from './ci_resource_header_skeleton_loader.vue';

export default {
  components: {
    CiIcon,
    CiResourceAbout,
    CiResourceHeaderSkeletonLoader,
    GlAvatar,
    GlAvatarLink,
    GlBadge,
  },
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
    pipelineStatus: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    resource: {
      type: Object,
      required: true,
    },
  },
  computed: {
    entityId() {
      return getIdFromGraphQLId(this.resource.id);
    },
    hasLatestVersion() {
      return this.latestVersion?.tagName;
    },
    hasPipelineStatus() {
      return this.pipelineStatus?.text;
    },
    latestVersion() {
      return this.resource.latestVersion;
    },
    versionBadgeText() {
      return this.latestVersion.tagName;
    },
    webPath() {
      return cleanLeadingSeparator(this.resource?.webPath);
    },
  },
};
</script>
<template>
  <div>
    <ci-resource-header-skeleton-loader v-if="isLoadingSharedData" class="gl-py-5" />
    <div v-else class="gl-display-flex gl-py-5">
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
          <div class="gl-font-lg gl-font-weight-bold">{{ resource.name }}</div>
          <gl-badge
            v-if="hasLatestVersion"
            size="sm"
            class="gl-ml-3 gl-my-1"
            :href="latestVersion.tagPath"
          >
            {{ versionBadgeText }}
          </gl-badge>
        </span>
        <ci-icon
          v-if="hasPipelineStatus"
          :status="pipelineStatus"
          show-status-text
          class="gl-mt-2"
        />
      </div>
    </div>
    <ci-resource-about
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
    <p v-else class="gl-mt-3">
      {{ resource.description }}
    </p>
  </div>
</template>
