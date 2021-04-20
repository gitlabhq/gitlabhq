<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import { mapActions, mapGetters, mapState } from 'vuex';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import { JOB_SIDEBAR } from '../constants';
import ArtifactsBlock from './artifacts_block.vue';
import CommitBlock from './commit_block.vue';
import JobRetryForwardDeploymentModal from './job_retry_forward_deployment_modal.vue';
import JobSidebarRetryButton from './job_sidebar_retry_button.vue';
import JobsContainer from './jobs_container.vue';
import JobSidebarDetailsContainer from './sidebar_job_details_container.vue';
import StagesDropdown from './stages_dropdown.vue';
import TriggerBlock from './trigger_block.vue';

export const forwardDeploymentFailureModalId = 'forward-deployment-failure';

export default {
  name: 'JobSidebar',
  i18n: {
    ...JOB_SIDEBAR,
  },
  borderTopClass: ['gl-border-t-solid', 'gl-border-t-1', 'gl-border-t-gray-100'],
  forwardDeploymentFailureModalId,
  components: {
    ArtifactsBlock,
    CommitBlock,
    GlButton,
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
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
    ...mapState(['job', 'stages', 'jobs', 'selectedStage']),
    retryButtonCategory() {
      return this.job.status && this.job.recoverable ? 'primary' : 'secondary';
    },
    hasArtifact() {
      // the artifact object will always have a locked property
      return Object.keys(this.job.artifact).length > 1;
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
        <div class="gl-py-5 gl-display-flex gl-align-items-center">
          <tooltip-on-truncate :title="job.name" truncate-target="child"
            ><h4 class="my-0 mr-2 gl-text-truncate">
              {{ job.name }}
            </h4>
          </tooltip-on-truncate>
          <div class="gl-flex-grow-1 gl-flex-shrink-0 gl-text-right">
            <job-sidebar-retry-button
              v-if="job.retry_path"
              :category="retryButtonCategory"
              :href="job.retry_path"
              :modal-id="$options.forwardDeploymentFailureModalId"
              variant="confirm"
              data-qa-selector="retry_button"
              data-testid="retry-button"
            />
            <gl-button
              v-if="job.cancel_path"
              :href="job.cancel_path"
              data-method="post"
              data-testid="cancel-button"
              rel="nofollow"
              >{{ $options.i18n.cancel }}
            </gl-button>
          </div>

          <gl-button
            :aria-label="$options.i18n.toggleSidebar"
            category="tertiary"
            class="gl-md-display-none gl-ml-2"
            icon="chevron-double-lg-right"
            @click="toggleSidebar"
          />
        </div>

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
