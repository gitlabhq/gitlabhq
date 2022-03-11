<script>
import {
  GlBadge,
  GlButton,
  GlCollapse,
  GlIcon,
  GlLink,
  GlTooltipDirective as GlTooltip,
  GlTruncate,
} from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { __, s__ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import DeploymentStatusBadge from './deployment_status_badge.vue';
import Commit from './commit.vue';

export default {
  components: {
    ClipboardButton,
    Commit,
    DeploymentStatusBadge,
    GlBadge,
    GlButton,
    GlCollapse,
    GlIcon,
    GlLink,
    GlTruncate,
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
      return this.commit?.shortId;
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
    commit() {
      return this.deployment?.commit;
    },
    user() {
      return this.deployment?.user;
    },
    username() {
      return `@${this.user.username}`;
    },
    userPath() {
      return this.user?.path;
    },
    deployable() {
      return this.deployment?.deployable;
    },
    jobName() {
      return this.deployable?.name;
    },
    jobPath() {
      return this.deployable?.buildPath;
    },
    refLabel() {
      return this.deployment?.tag ? this.$options.i18n.tag : this.$options.i18n.branch;
    },
    ref() {
      return this.deployment?.ref;
    },
    refName() {
      return this.ref?.name;
    },
    refPath() {
      return this.ref?.refPath;
    },
    needsApproval() {
      return this.deployment.pendingApprovalCount > 0;
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
    triggerer: s__('Deployment|Triggerer'),
    needsApproval: s__('Deployment|Needs Approval'),
    job: __('Job'),
    api: __('API'),
    branch: __('Branch'),
    tag: __('Tag'),
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
          <gl-badge v-if="needsApproval" variant="warning">
            {{ $options.i18n.needsApproval }}
          </gl-badge>
          <gl-badge v-if="latest" variant="info">{{ $options.i18n.latestBadge }}</gl-badge>
        </div>
        <div class="gl-display-flex gl-align-items-center gl-gap-x-5">
          <div
            v-if="iid"
            v-gl-tooltip
            class="gl-display-flex"
            :title="$options.i18n.deploymentId"
            :aria-label="$options.i18n.deploymentId"
          >
            <gl-icon ref="deployment-iid-icon" name="deployments" />
            <span class="gl-ml-2">#{{ iid }}</span>
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
          <time-ago-tooltip v-if="createdAt" :time="createdAt" class="gl-display-flex">
            <template #default="{ timeAgo }">
              <gl-icon name="calendar" />
              <span class="gl-mr-2 gl-white-space-nowrap">{{ timeAgo }}</span>
            </template>
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
    <commit v-if="commit" :commit="commit" class="gl-mt-3" />
    <div class="gl-mt-3"><slot name="approval"></slot></div>
    <gl-collapse :visible="visible">
      <div
        class="gl-display-flex gl-md-align-items-center gl-mt-5 gl-flex-direction-column gl-md-flex-direction-row gl-pr-4 gl-md-pr-0"
      >
        <div v-if="user" class="gl-display-flex gl-flex-direction-column gl-md-max-w-15p">
          <span class="gl-text-gray-500">{{ $options.i18n.triggerer }}</span>
          <gl-link :href="userPath" class="gl-font-monospace gl-mt-3">
            <gl-truncate :text="username" with-tooltip />
          </gl-link>
        </div>
        <div
          class="gl-display-flex gl-flex-direction-column gl-md-pl-7 gl-md-max-w-15p gl-mt-4 gl-md-mt-0"
        >
          <span class="gl-text-gray-500" :class="{ 'gl-ml-3': !deployable }">
            {{ $options.i18n.job }}
          </span>
          <gl-link v-if="jobPath" :href="jobPath" class="gl-font-monospace gl-mt-3">
            <gl-truncate :text="jobName" with-tooltip position="middle" />
          </gl-link>
          <span v-else-if="jobName" class="gl-font-monospace gl-mt-3">
            <gl-truncate :text="jobName" with-tooltip position="middle" />
          </span>
          <gl-badge v-else class="gl-font-monospace gl-mt-3" variant="info">
            {{ $options.i18n.api }}
          </gl-badge>
        </div>
        <div
          v-if="ref"
          class="gl-display-flex gl-flex-direction-column gl-md-pl-7 gl-md-max-w-15p gl-mt-4 gl-md-mt-0"
        >
          <span class="gl-text-gray-500">{{ refLabel }}</span>
          <gl-link :href="refPath" class="gl-font-monospace gl-mt-3">
            <gl-truncate :text="refName" with-tooltip />
          </gl-link>
        </div>
      </div>
    </gl-collapse>
  </div>
</template>
