<script>
import { GlIcon, GlLink } from '@gitlab/ui';
import { n__, s__, sprintf } from '~/locale';
import { getTimeago } from '~/lib/utils/datetime_utility';

export default {
  components: {
    GlIcon,
    GlLink,
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
      required: false,
      type: Number,
      default: 0,
    },
    openMergeRequestsCount: {
      required: false,
      type: Number,
      default: 0,
    },
    latestVersion: {
      required: false,
      type: Object,
      default: () => ({}),
    },
    webPath: {
      required: false,
      type: String,
      default: '',
    },
  },
  computed: {
    lastReleaseText() {
      if (this.latestVersion?.createdAt) {
        const timeAgo = getTimeago().format(this.latestVersion.createdAt);
        return sprintf(this.$options.i18n.lastRelease, { timeAgo });
      }

      return this.$options.i18n.lastReleaseMissing;
    },
    openIssuesText() {
      return n__('%d issue', '%d issues', this.openIssuesCount);
    },
    openMergeRequestText() {
      return n__('%d merge request', '%d merge requests', this.openMergeRequestsCount);
    },
    projectInfoItems() {
      return [
        {
          icon: 'project',
          link: `${this.webPath}`,
          text: this.$options.i18n.projectLink,
          isLoading: this.isLoadingSharedData,
        },
        {
          icon: 'issues',
          link: `${this.webPath}/issues`,
          text: this.openIssuesText,
          isLoading: this.isLoadingDetails,
        },
        {
          icon: 'merge-request',
          link: `${this.webPath}/merge_requests`,
          text: this.openMergeRequestText,
          isLoading: this.isLoadingDetails,
        },
        {
          icon: 'clock',
          text: this.lastReleaseText,
          isLoading: this.isLoadingSharedData,
        },
      ];
    },
  },
  i18n: {
    projectLink: s__('CiCatalog|Go to the project'),
    lastRelease: s__('CiCatalog|Released %{timeAgo}'),
    lastReleaseMissing: s__('CiCatalog|No release available'),
  },
};
</script>

<template>
  <div class="gl-py-2 gl-sm-display-flex gl-gap-5">
    <span
      v-for="item in projectInfoItems"
      :key="`${item.icon}`"
      class="gl-display-flex gl-align-items-center gl-mb-3 gl-sm-mb-0"
    >
      <gl-icon class="gl-text-primary gl-mr-2" :name="item.icon" />
      <div
        v-if="item.isLoading"
        class="gl-animate-skeleton-loader gl-h-4 gl-rounded-base gl-w-15"
        data-testid="skeleton-loading-line"
      ></div>
      <template v-else>
        <gl-link v-if="item.link" :href="item.link"> {{ item.text }} </gl-link>
        <span v-else class="gl-text-secondary">
          {{ item.text }}
        </span>
      </template>
    </span>
  </div>
</template>
