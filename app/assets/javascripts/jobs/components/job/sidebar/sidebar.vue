<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import { JOB_SIDEBAR_COPY, forwardDeploymentFailureModalId } from '~/jobs/constants';
import ArtifactsBlock from './artifacts_block.vue';
import CommitBlock from './commit_block.vue';
import JobsContainer from './jobs_container.vue';
import JobRetryForwardDeploymentModal from './job_retry_forward_deployment_modal.vue';
import JobSidebarDetailsContainer from './sidebar_job_details_container.vue';
import SidebarHeader from './sidebar_header.vue';
import StagesDropdown from './stages_dropdown.vue';
import TriggerBlock from './trigger_block.vue';

export default {
  name: 'JobSidebar',
  i18n: {
    ...JOB_SIDEBAR_COPY,
  },
  borderTopClass: ['gl-border-t-solid', 'gl-border-t-1', 'gl-border-t-gray-100'],
  forwardDeploymentFailureModalId,
  components: {
    ArtifactsBlock,
    CommitBlock,
    GlButton,
    GlIcon,
    JobsContainer,
    JobRetryForwardDeploymentModal,
    JobSidebarDetailsContainer,
    SidebarHeader,
    StagesDropdown,
    TriggerBlock,
  },
  props: {
    artifactHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
    ...mapState(['job', 'stages', 'jobs', 'selectedStage']),
    hasArtifact() {
      // the artifact object will always have a locked property
      return Object.keys(this.job.artifact).length > 1;
    },
    hasTriggers() {
      return !isEmpty(this.job.trigger);
    },
    commit() {
      return this.job?.pipeline?.commit || {};
    },
    selectedStageData() {
      return this.stages.find((val) => val.name === this.selectedStage);
    },
    shouldShowJobRetryForwardDeploymentModal() {
      return this.job.retry_path && this.hasForwardDeploymentFailure;
    },
  },
  watch: {
    job(value, oldValue) {
      const hasNewStatus = value.status.text !== oldValue.status.text;
      const isCurrentStage = value?.stage === this.selectedStage;

      if (hasNewStatus && isCurrentStage) {
        this.fetchJobsForStage(this.selectedStageData);
      }
    },
  },
  methods: {
    ...mapActions(['fetchJobsForStage']),
  },
};
</script>
<template>
  <aside class="right-sidebar build-sidebar" data-offset-top="101" data-spy="affix">
    <div class="sidebar-container">
      <div class="blocks-container">
        <sidebar-header
          :rest-job="job"
          :job-id="job.id"
          @updateVariables="$emit('updateVariables')"
        />
        <div
          v-if="job.terminal_path || job.new_issue_path"
          class="gl-py-5"
          :class="$options.borderTopClass"
        >
          <gl-button
            v-if="job.new_issue_path"
            :href="job.new_issue_path"
            category="secondary"
            variant="confirm"
            data-testid="job-new-issue"
          >
            {{ $options.i18n.newIssue }}
          </gl-button>
          <gl-button
            v-if="job.terminal_path"
            :href="job.terminal_path"
            target="_blank"
            data-testid="terminal-link"
          >
            {{ $options.i18n.debug }}
            <gl-icon name="external-link" />
          </gl-button>
        </div>

        <job-sidebar-details-container class="gl-py-5" :class="$options.borderTopClass" />

        <artifacts-block
          v-if="hasArtifact"
          class="gl-py-5"
          :class="$options.borderTopClass"
          :artifact="job.artifact"
          :help-url="artifactHelpUrl"
        />

        <trigger-block
          v-if="hasTriggers"
          class="gl-py-5"
          :class="$options.borderTopClass"
          :trigger="job.trigger"
        />

        <commit-block
          :commit="commit"
          class="gl-py-5"
          :class="$options.borderTopClass"
          :merge-request="job.merge_request"
        />

        <stages-dropdown
          v-if="job.pipeline"
          class="gl-py-5"
          :class="$options.borderTopClass"
          :pipeline="job.pipeline"
          :selected-stage="selectedStage"
          :stages="stages"
          @requestSidebarStageDropdown="fetchJobsForStage"
        />
      </div>

      <jobs-container v-if="jobs.length" :job-id="job.id" :jobs="jobs" />
    </div>
    <job-retry-forward-deployment-modal
      v-if="shouldShowJobRetryForwardDeploymentModal"
      :modal-id="$options.forwardDeploymentFailureModalId"
      :href="job.retry_path"
    />
  </aside>
</template>
