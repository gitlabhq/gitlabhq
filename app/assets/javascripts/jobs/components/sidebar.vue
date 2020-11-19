<script>
import { isEmpty } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlButton, GlIcon, GlLink } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import ArtifactsBlock from './artifacts_block.vue';
import JobSidebarRetryButton from './job_sidebar_retry_button.vue';
import JobRetryForwardDeploymentModal from './job_retry_forward_deployment_modal.vue';
import TriggerBlock from './trigger_block.vue';
import CommitBlock from './commit_block.vue';
import StagesDropdown from './stages_dropdown.vue';
import JobsContainer from './jobs_container.vue';
import JobSidebarDetailsContainer from './sidebar_job_details_container.vue';
import { JOB_SIDEBAR } from '../constants';

export const forwardDeploymentFailureModalId = 'forward-deployment-failure';

export default {
  name: 'JobSidebar',
  i18n: {
    ...JOB_SIDEBAR,
  },
  forwardDeploymentFailureModalId,
  components: {
    ArtifactsBlock,
    CommitBlock,
    GlButton,
    GlLink,
    GlIcon,
    JobsContainer,
    JobSidebarRetryButton,
    JobRetryForwardDeploymentModal,
    JobSidebarDetailsContainer,
    StagesDropdown,
    TooltipOnTruncate,
    TriggerBlock,
  },
  props: {
    artifactHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
    runnerHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
    ...mapState(['job', 'stages', 'jobs', 'selectedStage']),
    retryButtonClass() {
      let className = 'btn btn-retry';
      className +=
        this.job.status && this.job.recoverable ? ' btn-primary' : ' btn-inverted-secondary';
      return className;
    },
    hasArtifact() {
      return !isEmpty(this.job.artifact);
    },
    hasTriggers() {
      return !isEmpty(this.job.trigger);
    },
    hasStages() {
      return this.job?.pipeline?.stages?.length > 0;
    },
    commit() {
      return this.job?.pipeline?.commit || {};
    },
    shouldShowJobRetryForwardDeploymentModal() {
      return this.job.retry_path && this.hasForwardDeploymentFailure;
    },
  },
  methods: {
    ...mapActions(['fetchJobsForStage', 'toggleSidebar']),
  },
};
</script>
<template>
  <aside class="right-sidebar build-sidebar" data-offset-top="101" data-spy="affix">
    <div class="sidebar-container">
      <div class="blocks-container">
        <div class="block d-flex flex-nowrap align-items-center">
          <tooltip-on-truncate :title="job.name" truncate-target="child"
            ><h4 class="my-0 mr-2 gl-text-truncate">
              {{ job.name }}
            </h4>
          </tooltip-on-truncate>
          <div class="flex-grow-1 flex-shrink-0 text-right">
            <job-sidebar-retry-button
              v-if="job.retry_path"
              :class="retryButtonClass"
              :href="job.retry_path"
              :modal-id="$options.forwardDeploymentFailureModalId"
              data-qa-selector="retry_button"
              data-testid="retry-button"
            />
            <gl-link
              v-if="job.cancel_path"
              :href="job.cancel_path"
              class="btn btn-default"
              data-method="post"
              data-testid="cancel-button"
              rel="nofollow"
              >{{ $options.i18n.cancel }}
            </gl-link>
          </div>

          <gl-button
            :aria-label="$options.i18n.toggleSidebar"
            category="tertiary"
            class="gl-display-md-none gl-ml-2 js-sidebar-build-toggle"
            icon="chevron-double-lg-right"
            @click="toggleSidebar"
          />
        </div>

        <div v-if="job.terminal_path || job.new_issue_path" class="block retry-link">
          <gl-link
            v-if="job.new_issue_path"
            :href="job.new_issue_path"
            class="btn btn-success btn-inverted float-left mr-2"
            data-testid="job-new-issue"
            >{{ $options.i18n.newIssue }}
          </gl-link>
          <gl-link
            v-if="job.terminal_path"
            :href="job.terminal_path"
            class="btn btn-primary btn-inverted visible-md-block visible-lg-block float-left"
            target="_blank"
            data-testid="terminal-link"
          >
            {{ $options.i18n.debug }}
            <gl-icon :size="14" name="external-link" />
          </gl-link>
        </div>
        <job-sidebar-details-container :runner-help-url="runnerHelpUrl" />
        <artifacts-block v-if="hasArtifact" :artifact="job.artifact" :help-url="artifactHelpUrl" />
        <trigger-block v-if="hasTriggers" :trigger="job.trigger" />
        <commit-block
          :commit="commit"
          :is-last-block="hasStages"
          :merge-request="job.merge_request"
        />

        <stages-dropdown
          v-if="job.pipeline"
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
