<script>
import { s__, sprintf } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import UserAvatarLink from '~/vue_shared/components/user_avatar/user_avatar_link.vue';
import TimeagoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import EmptySecurityDashboard from './components/empty_security_dashboard.vue';
import SplitSecurityReport from './split_security_reports_app.vue';

export default {
  components: {
    EmptySecurityDashboard,
    UserAvatarLink,
    Icon,
    SplitSecurityReport,
    TimeagoTooltip,
  },
  props: {
    hasPipelineData: {
      type: Boolean,
      required: false,
      default: false,
    },
    emptyStateIllustrationPath: {
      type: String,
      required: false,
      default: null,
    },
    securityDashboardHelpPath: {
      type: String,
      required: false,
      default: null,
    },
    alwaysOpen: {
      type: Boolean,
      required: false,
      default: false,
    },
    headBlobPath: {
      type: String,
      required: false,
      default: null,
    },
    sastHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    dastHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    sastContainerHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    dependencyScanningHeadPath: {
      type: String,
      required: false,
      default: null,
    },
    sastHelpPath: {
      type: String,
      required: false,
      default: null,
    },
    sastContainerHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    dastHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    dependencyScanningHelpPath: {
      type: String,
      required: false,
      default: null,
    },
    vulnerabilityFeedbackPath: {
      type: String,
      required: false,
      default: '',
    },
    vulnerabilityFeedbackHelpPath: {
      type: String,
      required: false,
      default: '',
    },
    pipelineId: {
      type: Number,
      required: false,
      default: null,
    },
    commit: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    triggeredBy: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    branch: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    pipeline: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    canCreateFeedback: {
      type: Boolean,
      required: true,
    },
    canCreateIssue: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    headline() {
      return sprintf(
        s__('SecurityDashboard|Pipeline %{pipelineLink} triggered'),
        {
          pipelineLink: `<a href="${this.pipeline.path}">#${this.pipeline.id}</a>`,
        },
        false,
      );
    },
  },
};
</script>
<template>
  <div>
    <div
      v-if="hasPipelineData"
      class="card security-dashboard prepend-top-default"
    >
      <div class="card-header">
        <span class="js-security-dashboard-left">
          <span v-html="headline"></span>
          <timeago-tooltip :time="pipeline.created"/>
          {{ __('by') }}
          <user-avatar-link
            :link-href="triggeredBy.path"
            :img-src="triggeredBy.avatarPath"
            :img-alt="triggeredBy.name"
            :img-size="24"
            :username="triggeredBy.name"
            class="avatar-image-container"
          />
        </span>
        <span class="js-security-dashboard-right pull-right">
          <icon name="branch"/>
          <a
            :href="branch.path"
            class="monospace"
          >{{ branch.id }}</a>
          <span class="text-muted prepend-left-5 append-right-5">&middot;</span>
          <icon name="commit"/>
          <a
            :href="commit.path"
            class="monospace"
          >{{ commit.id }}</a>
        </span>
      </div>
      <split-security-report
        :pipeline-id="pipelineId"
        :head-blob-path="headBlobPath"
        :sast-head-path="sastHeadPath"
        :dast-head-path="dastHeadPath"
        :sast-container-head-path="sastContainerHeadPath"
        :dependency-scanning-head-path="dependencyScanningHeadPath"
        :sast-help-path="sastHelpPath"
        :sast-container-help-path="sastContainerHelpPath"
        :dast-help-path="dastHelpPath"
        :dependency-scanning-help-path="dependencyScanningHelpPath"
        :vulnerability-feedback-path="vulnerabilityFeedbackPath"
        :vulnerability-feedback-help-path="vulnerabilityFeedbackHelpPath"
        :can-create-feedback="canCreateFeedback"
        :can-create-issue="canCreateIssue"
        always-open
      />
    </div>
    <empty-security-dashboard
      v-else
      :help-path="securityDashboardHelpPath"
      :illustration-path="emptyStateIllustrationPath"
    />
  </div>
</template>
