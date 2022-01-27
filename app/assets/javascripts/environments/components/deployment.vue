<script>
import { GlBadge, GlButton, GlCollapse, GlIcon, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeploymentStatusBadge from './deployment_status_badge.vue';

export default {
  components: {
    ClipboardButton,
    DeploymentStatusBadge,
    GlBadge,
    GlButton,
    GlCollapse,
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
  data() {
    return { visible: false };
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
    isMobile() {
      return !GlBreakpointInstance.isDesktop();
    },
    detailsButton() {
      return this.visible
        ? { text: this.$options.i18n.hideDetails, icon: 'expand-up' }
        : { text: this.$options.i18n.showDetails, icon: 'expand-down' };
    },
    detailsButtonClasses() {
      return this.isMobile ? 'gl-sr-only' : '';
    },
  },
  methods: {
    toggleCollapse() {
      this.visible = !this.visible;
    },
  },
  i18n: {
    latestBadge: s__('Deployment|Latest Deployed'),
    deploymentId: s__('Deployment|Deployment ID'),
    copyButton: __('Copy commit SHA'),
    commitSha: __('Commit SHA'),
    showDetails: __('Show details'),
    hideDetails: __('Hide details'),
  },
  headerClasses: [
    'gl-display-flex',
    'gl-align-items-flex-start',
    'gl-md-align-items-center',
    'gl-justify-content-space-between',
    'gl-pr-6',
  ],
  headerDetailsClasses: [
    'gl-display-flex',
    'gl-flex-direction-column',
    'gl-md-flex-direction-row',
    'gl-align-items-flex-start',
    'gl-md-align-items-center',
    'gl-font-sm',
    'gl-text-gray-700',
  ],
  deploymentStatusClasses: [
    'gl-display-flex',
    'gl-gap-x-3',
    'gl-mr-0',
    'gl-md-mr-5',
    'gl-mb-3',
    'gl-md-mb-0',
  ],
};
</script>
<template>
  <div>
    <div :class="$options.headerClasses">
      <div :class="$options.headerDetailsClasses">
        <div :class="$options.deploymentStatusClasses">
          <deployment-status-badge v-if="status" :status="status" />
          <gl-badge v-if="latest" variant="info">{{ $options.i18n.latestBadge }}</gl-badge>
        </div>
        <div class="gl-display-flex gl-align-items-center gl-gap-x-5">
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
          </div>
          <time-ago-tooltip v-if="createdAt" :time="createdAt">
            <template #default="{ timeAgo }"> <gl-icon name="calendar" /> {{ timeAgo }} </template>
          </time-ago-tooltip>
        </div>
      </div>
      <gl-button
        ref="details-toggle"
        category="tertiary"
        :icon="detailsButton.icon"
        :button-text-classes="detailsButtonClasses"
        @click="toggleCollapse"
      >
        {{ detailsButton.text }}
      </gl-button>
    </div>
    <gl-collapse :visible="visible" />
  </div>
</template>
