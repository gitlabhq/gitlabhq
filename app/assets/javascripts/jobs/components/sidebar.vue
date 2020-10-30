<script>
import { isEmpty } from 'lodash';
import { mapActions, mapState } from 'vuex';
import { GlButton, GlIcon, GlLink } from '@gitlab/ui';
import TooltipOnTruncate from '~/vue_shared/components/tooltip_on_truncate.vue';
import ArtifactsBlock from './artifacts_block.vue';
import TriggerBlock from './trigger_block.vue';
import CommitBlock from './commit_block.vue';
import StagesDropdown from './stages_dropdown.vue';
import JobsContainer from './jobs_container.vue';
import SidebarJobDetailsContainer from './sidebar_job_details_container.vue';

export default {
  name: 'JobSidebar',
  components: {
    ArtifactsBlock,
    CommitBlock,
    GlIcon,
    TriggerBlock,
    StagesDropdown,
    JobsContainer,
    GlLink,
    GlButton,
    SidebarJobDetailsContainer,
    TooltipOnTruncate,
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
    ...mapState(['job', 'stages', 'jobs', 'selectedStage']),
    retryButtonClass() {
      let className = 'js-retry-button btn btn-retry';
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
            <gl-link
              v-if="job.retry_path"
              :class="retryButtonClass"
              :href="job.retry_path"
              data-method="post"
              data-qa-selector="retry_button"
              rel="nofollow"
              >{{ __('Retry') }}
            </gl-link>
            <gl-link
              v-if="job.cancel_path"
              :href="job.cancel_path"
              class="js-cancel-job btn btn-default"
              data-method="post"
              rel="nofollow"
              >{{ __('Cancel') }}
            </gl-link>
          </div>

          <gl-button
            :aria-label="__('Toggle Sidebar')"
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
            >{{ __('New issue') }}
          </gl-link>
          <gl-link
            v-if="job.terminal_path"
            :href="job.terminal_path"
            class="js-terminal-link btn btn-primary btn-inverted visible-md-block visible-lg-block float-left"
            target="_blank"
          >
            {{ __('Debug') }}
            <gl-icon :size="14" name="external-link" />
          </gl-link>
        </div>
        <sidebar-job-details-container :runner-help-url="runnerHelpUrl" />
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
  </aside>
</template>
