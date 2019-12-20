<script>
import _ from 'underscore';
import { mapActions, mapState } from 'vuex';
import { GlLink, GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
import timeagoMixin from '~/vue_shared/mixins/timeago';
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';
import Icon from '~/vue_shared/components/icon.vue';
import DetailRow from './sidebar_detail_row.vue';
import ArtifactsBlock from './artifacts_block.vue';
import TriggerBlock from './trigger_block.vue';
import CommitBlock from './commit_block.vue';
import StagesDropdown from './stages_dropdown.vue';
import JobsContainer from './jobs_container.vue';

export default {
  name: 'JobSidebar',
  components: {
    ArtifactsBlock,
    CommitBlock,
    DetailRow,
    Icon,
    TriggerBlock,
    StagesDropdown,
    JobsContainer,
    GlLink,
    GlButton,
  },
  mixins: [timeagoMixin],
  props: {
    runnerHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState(['job', 'stages', 'jobs', 'selectedStage']),
    coverage() {
      return `${this.job.coverage}%`;
    },
    duration() {
      return timeIntervalInWords(this.job.duration);
    },
    queued() {
      return timeIntervalInWords(this.job.queued);
    },
    runnerId() {
      return `${this.job.runner.description} (#${this.job.runner.id})`;
    },
    retryButtonClass() {
      let className = 'js-retry-button btn btn-retry';
      className +=
        this.job.status && this.job.recoverable ? ' btn-primary' : ' btn-inverted-secondary';
      return className;
    },
    hasTimeout() {
      return this.job.metadata != null && this.job.metadata.timeout_human_readable !== null;
    },
    timeout() {
      if (this.job.metadata == null) {
        return '';
      }

      let t = this.job.metadata.timeout_human_readable;
      if (this.job.metadata.timeout_source !== '') {
        t += sprintf(__(` (from %{timeoutSource})`), {
          timeoutSource: this.job.metadata.timeout_source,
        });
      }

      return t;
    },
    renderBlock() {
      return (
        this.job.duration ||
        this.job.finished_at ||
        this.job.erased_at ||
        this.job.queued ||
        this.hasTimeout ||
        this.job.runner ||
        this.job.coverage ||
        this.job.tags.length
      );
    },
    hasArtifact() {
      return !_.isEmpty(this.job.artifact);
    },
    hasTriggers() {
      return !_.isEmpty(this.job.trigger);
    },
    hasStages() {
      return (
        (this.job &&
          this.job.pipeline &&
          this.job.pipeline.stages &&
          this.job.pipeline.stages.length > 0) ||
        false
      );
    },
    commit() {
      return this.job.pipeline && this.job.pipeline.commit ? this.job.pipeline.commit : {};
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
          <h4 class="my-0 mr-2 text-break-word">{{ job.name }}</h4>
          <div class="flex-grow-1 flex-shrink-0 text-right">
            <gl-link
              v-if="job.retry_path"
              :class="retryButtonClass"
              :href="job.retry_path"
              data-method="post"
              rel="nofollow"
              >{{ __('Retry') }}</gl-link
            >
            <gl-link
              v-if="job.cancel_path"
              :href="job.cancel_path"
              class="js-cancel-job btn btn-default"
              data-method="post"
              rel="nofollow"
              >{{ __('Cancel') }}</gl-link
            >
          </div>

          <gl-button
            :aria-label="__('Toggle Sidebar')"
            type="button"
            class="btn btn-blank gutter-toggle float-right d-block d-md-none js-sidebar-build-toggle"
            @click="toggleSidebar"
          >
            <i aria-hidden="true" data-hidden="true" class="fa fa-angle-double-right"></i>
          </gl-button>
        </div>

        <div v-if="job.terminal_path || job.new_issue_path" class="block retry-link">
          <gl-link
            v-if="job.new_issue_path"
            :href="job.new_issue_path"
            class="js-new-issue btn btn-success btn-inverted float-left mr-2"
            >{{ __('New issue') }}</gl-link
          >
          <gl-link
            v-if="job.terminal_path"
            :href="job.terminal_path"
            class="js-terminal-link btn btn-primary btn-inverted visible-md-block visible-lg-block float-left"
            target="_blank"
          >
            {{ __('Debug') }} <icon name="external-link" :size="14" />
          </gl-link>
        </div>

        <div v-if="renderBlock" class="block">
          <detail-row
            v-if="job.duration"
            :value="duration"
            class="js-job-duration"
            title="Duration"
          />
          <detail-row
            v-if="job.finished_at"
            :value="timeFormatted(job.finished_at)"
            class="js-job-finished"
            title="Finished"
          />
          <detail-row
            v-if="job.erased_at"
            :value="timeFormatted(job.erased_at)"
            class="js-job-erased"
            title="Erased"
          />
          <detail-row v-if="job.queued" :value="queued" class="js-job-queued" title="Queued" />
          <detail-row
            v-if="hasTimeout"
            :help-url="runnerHelpUrl"
            :value="timeout"
            class="js-job-timeout"
            title="Timeout"
          />
          <detail-row v-if="job.runner" :value="runnerId" class="js-job-runner" title="Runner" />
          <detail-row
            v-if="job.coverage"
            :value="coverage"
            class="js-job-coverage"
            title="Coverage"
          />
          <p v-if="job.tags.length" class="build-detail-row js-job-tags">
            <span class="font-weight-bold">{{ __('Tags:') }}</span>
            <span v-for="(tag, i) in job.tags" :key="i" class="badge badge-primary mr-1">{{
              tag
            }}</span>
          </p>
        </div>

        <artifacts-block v-if="hasArtifact" :artifact="job.artifact" />
        <trigger-block v-if="hasTriggers" :trigger="job.trigger" />
        <commit-block
          :is-last-block="hasStages"
          :commit="commit"
          :merge-request="job.merge_request"
        />

        <stages-dropdown
          :stages="stages"
          :pipeline="job.pipeline"
          :selected-stage="selectedStage"
          @requestSidebarStageDropdown="fetchJobsForStage"
        />
      </div>

      <jobs-container v-if="jobs.length" :jobs="jobs" :job-id="job.id" />
    </div>
  </aside>
</template>
