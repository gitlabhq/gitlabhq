<script>
import {
  GlBadge,
  GlIcon,
  GlLink,
  GlSkeletonLoader,
  GlSprintf,
  GlTooltipDirective as GlTooltip,
  GlTruncateText,
} from '@gitlab/ui';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__, __ } from '~/locale';
import DeploymentStatusLink from '~/environments/components/deployment_status_link.vue';
import DeploymentCommit from '~/environments/components/commit.vue';
import { renderGFM } from '~/behaviors/markdown/render_gfm';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { isFinished } from '../utils';

export default {
  components: {
    GlBadge,
    GlIcon,
    GlLink,
    GlSkeletonLoader,
    GlSprintf,
    GlTruncateText,
    ClipboardButton,
    TimeAgoTooltip,
    DeploymentStatusLink,
    DeploymentCommit,
  },
  directives: {
    GlTooltip,
    SafeHtml,
  },
  props: {
    deployment: {
      required: true,
      type: Object,
    },
    environment: {
      required: true,
      type: Object,
    },
    release: {
      required: false,
      default: null,
      type: Object,
    },
    loading: {
      required: false,
      default: false,
      type: Boolean,
    },
  },
  computed: {
    iid() {
      return this.deployment.iid;
    },
    status() {
      return this.deployment.status?.toLowerCase() ?? '';
    },
    job() {
      return this.deployment.job;
    },
    needsApproval() {
      return (
        !this.isFinished(this.deployment) &&
        this.deployment.approvalSummary?.status === 'PENDING_APPROVAL'
      );
    },
    environmentName() {
      return this.environment.name;
    },
    environmentPath() {
      return this.environment.path;
    },
    commit() {
      return this.deployment.commit || {};
    },
    commitPath() {
      return this.deployment.commit.webPath || '';
    },
    shortSha() {
      return this.deployment.commit?.shortId;
    },
    createdAt() {
      return this.deployment.createdAt || '';
    },
    finishedAt() {
      return this.deployment.finishedAt || '';
    },
    triggerer() {
      return this.deployment.triggerer;
    },
    triggererUsername() {
      return this.triggerer?.username;
    },
    triggererUrl() {
      return this.triggerer?.webUrl;
    },
    timeagoText() {
      return this.isFinished(this.deployment)
        ? this.$options.i18n.finishedTimeagoText
        : this.$options.i18n.startedTimeagoText;
    },
    timeagoTime() {
      return this.isFinished(this.deployment) ? this.finishedAt : this.createdAt;
    },
  },
  mounted() {
    renderGFM(this.$refs['gfm-content']);
  },
  methods: {
    isFinished,
  },
  safeHtmlConfig: { ADD_TAGS: ['gl-emoji'] },
  i18n: {
    copyButton: __('Copy commit SHA'),
    needsApproval: s__('Deployment|Needs Approval'),
    startedTimeagoText: s__('Deployment|Started %{timeago} by %{username}'),
    finishedTimeagoText: s__('Deployment|Finished %{timeago} by %{username}'),
    releaseNotes: s__('Deployment|%{releaseName} release notes:'),
  },
};
</script>
<template>
  <div v-if="loading" class="gl-mt-4">
    <gl-skeleton-loader class="gl-mt-3" :height="20" viewbox="0 0 400 20">
      <rect width="26" height="8" rx="4" />
      <rect width="26" x="28" height="8" rx="4" />
      <rect width="36" x="56" height="8" rx="4" />
      <rect width="82" x="94" height="8" rx="4" />
      <rect width="176" y="10" height="8" rx="4" />
    </gl-skeleton-loader>
  </div>
  <div v-else>
    <div class="gl-mb-3 gl-flex gl-flex-wrap gl-items-center gl-gap-3">
      <deployment-status-link :status="status" :deployment-job="job" />
      <gl-badge v-if="needsApproval" variant="warning">
        {{ $options.i18n.needsApproval }}
      </gl-badge>
      <div class="gl-flex gl-items-center">
        <gl-icon name="environment" class="gl-mr-2" />
        <gl-link :href="environmentPath">{{ environmentName }}</gl-link>
      </div>
      <div v-if="shortSha" class="gl-flex gl-items-center gl-font-monospace">
        <gl-icon ref="deployment-commit-icon" name="commit" class="gl-mr-2" />
        <gl-link v-gl-tooltip :title="$options.i18n.commitSha" :href="commitPath">
          {{ shortSha }}
        </gl-link>
        <clipboard-button
          :text="shortSha"
          category="tertiary"
          :title="$options.i18n.copyButton"
          size="small"
        />
      </div>
      <time-ago-tooltip v-if="timeagoTime" :time="timeagoTime" class="gl-flex gl-items-center">
        <template #default="{ timeAgo }">
          <gl-icon name="calendar" class="gl-mr-2" />
          <span class="gl-mr-2 gl-whitespace-nowrap">
            <gl-sprintf :message="timeagoText">
              <template #timeago>{{ timeAgo }}</template>
              <template #username>
                <gl-link :href="triggererUrl">@{{ triggererUsername }}</gl-link>
              </template>
            </gl-sprintf>
          </span>
        </template>
      </time-ago-tooltip>
    </div>
    <deployment-commit :commit="commit" />
    <p v-if="release" class="gl-my-3 gl-font-bold">
      <gl-sprintf :message="$options.i18n.releaseNotes">
        <template #releaseName>
          <gl-link :href="release.links.selfUrl" data-testid="release-page-link">
            {{ release.name }}
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
    <gl-truncate-text v-if="release" :lines="2" :mobile-lines="2">
      <div
        ref="gfm-content"
        v-safe-html:[$options.safeHtmlConfig]="release.descriptionHtml"
        class="md gl-z-0"
        data-testid="release-description-content"
      ></div>
    </gl-truncate-text>
  </div>
</template>
