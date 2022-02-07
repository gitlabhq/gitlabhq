<script>
import {
  GlBadge,
  GlButton,
  GlCollapse,
  GlIcon,
  GlLink,
  GlTooltipDirective as GlTooltip,
} from '@gitlab/ui';
import { GlBreakpointInstance } from '@gitlab/ui/dist/utils';
import { __, s__ } from '~/locale';
import { truncate } from '~/lib/utils/text_utility';
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
      return truncate(this.user?.username, 25);
    },
    userPath() {
      return this.user?.path;
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
    <commit v-if="commit" :commit="commit" class="gl-mt-3" />
    <gl-collapse :visible="visible">
      <div class="gl-display-flex gl-align-items-center gl-mt-5">
        <div v-if="user" class="gl-display-flex gl-flex-direction-column">
          <span class="gl-text-gray-500 gl-font-weight-bold">{{ $options.i18n.triggerer }}</span>
          <gl-link :href="userPath" class="gl-font-monospace gl-mt-3"> @{{ username }} </gl-link>
        </div>
      </div>
    </gl-collapse>
  </div>
</template>
