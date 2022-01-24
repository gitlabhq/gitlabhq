<script>
import { GlBadge, GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeploymentStatusBadge from './deployment_status_badge.vue';

export default {
  components: {
    ClipboardButton,
    DeploymentStatusBadge,
    GlBadge,
    GlIcon,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip,
  },
  props: {
    deployment: {
      type: Object,
      required: true,
    },
    latest: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    status() {
      return this.deployment?.status;
    },
    iid() {
      return this.deployment?.iid;
    },
    shortSha() {
      return this.deployment?.commit?.shortId;
    },
    createdAt() {
      return this.deployment?.createdAt;
    },
  },
  i18n: {
    latestBadge: s__('Deployment|Latest Deployed'),
    deploymentId: s__('Deployment|Deployment ID'),
    copyButton: __('Copy commit SHA'),
    commitSha: __('Commit SHA'),
  },
};
</script>
<template>
  <div class="gl-display-flex gl-align-items-center gl-gap-x-3 gl-font-sm gl-text-gray-700">
    <deployment-status-badge v-if="status" :status="status" />
    <gl-badge v-if="latest" variant="info">{{ $options.i18n.latestBadge }}</gl-badge>
    <div
      v-if="iid"
      v-gl-tooltip
      :title="$options.i18n.deploymentId"
      :aria-label="$options.i18n.deploymentId"
    >
      <gl-icon ref="deployment-iid-icon" name="deployments" /> #{{ iid }}
    </div>
    <div
      v-if="shortSha"
      data-testid="deployment-commit-sha"
      class="gl-font-monospace gl-display-flex gl-align-items-center"
    >
      <gl-icon ref="deployment-commit-icon" name="commit" class="gl-mr-2" />
      <span v-gl-tooltip :title="$options.i18n.commitSha">{{ shortSha }}</span>
      <clipboard-button
        :text="shortSha"
        category="tertiary"
        :title="$options.i18n.copyButton"
        size="small"
      />
      <time-ago-tooltip v-if="createdAt" :time="createdAt" class="gl-ml-5!">
        <template #default="{ timeAgo }"> <gl-icon name="calendar" /> {{ timeAgo }} </template>
      </time-ago-tooltip>
    </div>
  </div>
</template>
