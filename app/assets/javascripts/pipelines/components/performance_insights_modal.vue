<script>
import { GlAlert, GlCard, GlLink, GlLoadingIcon, GlModal } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { humanizeTimeInterval } from '~/lib/utils/datetime_utility';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import getPerformanceInsightsQuery from '../graphql/queries/get_performance_insights.query.graphql';
import { performanceModalId } from '../constants';
import { calculateJobStats, calculateSlowestFiveJobs } from '../utils';

export default {
  name: 'PerformanceInsightsModal',
  i18n: {
    queuedCardHeader: s__('Pipeline|Longest queued job'),
    queuedCardHelp: s__(
      'Pipeline|The longest queued job is the job that spent the longest time in the pending state, waiting to be picked up by a Runner',
    ),
    executedCardHeader: s__('Pipeline|Last executed job'),
    executedCardHelp: s__(
      'Pipeline|The last executed job is the last job to start in the pipeline.',
    ),
    viewDependency: s__('Pipeline|View dependency'),
    slowJobsTitle: s__('Pipeline|Five slowest jobs'),
    feeback: __('Feedback issue'),
    insightsLimit: s__('Pipeline|Only able to show first 100 results'),
  },
  modal: {
    title: s__('Pipeline|Performance insights'),
    actionCancel: {
      text: __('Close'),
      attributes: {
        variant: 'confirm',
      },
    },
  },
  performanceModalId,
  components: {
    GlAlert,
    GlCard,
    GlLink,
    GlModal,
    GlLoadingIcon,
    HelpPopover,
  },
  inject: {
    pipelineIid: {
      default: '',
    },
    pipelineProjectPath: {
      default: '',
    },
  },
  apollo: {
    jobs: {
      query: getPerformanceInsightsQuery,
      variables() {
        return {
          fullPath: this.pipelineProjectPath,
          iid: this.pipelineIid,
        };
      },
      update(data) {
        return data.project?.pipeline?.jobs;
      },
    },
  },
  data() {
    return {
      jobs: null,
    };
  },
  computed: {
    longestQueuedJob() {
      return calculateJobStats(this.jobs, 'queuedDuration');
    },
    lastExecutedJob() {
      return calculateJobStats(this.jobs, 'startedAt');
    },
    slowestFiveJobs() {
      return calculateSlowestFiveJobs(this.jobs);
    },
    queuedDurationDisplay() {
      return humanizeTimeInterval(this.longestQueuedJob.queuedDuration);
    },
    showLimitMessage() {
      return this.jobs.pageInfo.hasNextPage;
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.performanceModalId"
    :title="$options.modal.title"
    :action-cancel="$options.modal.actionCancel"
  >
    <gl-loading-icon v-if="$apollo.queries.jobs.loading" size="lg" />

    <template v-else>
      <gl-alert class="gl-mb-4" :dismissible="false">
        <p v-if="showLimitMessage" data-testid="limit-alert-text">
          {{ $options.i18n.insightsLimit }}
        </p>
        <gl-link href="https://gitlab.com/gitlab-org/gitlab/-/issues/365902" class="gl-mt-5">
          {{ $options.i18n.feeback }}
        </gl-link>
      </gl-alert>

      <div class="gl-display-flex gl-justify-content-space-between gl-mt-2 gl-mb-7">
        <gl-card class="gl-w-half gl-mr-7 gl-text-center">
          <template #header>
            <span class="gl-font-weight-bold">{{ $options.i18n.queuedCardHeader }}</span>
            <help-popover>
              {{ $options.i18n.queuedCardHelp }}
            </help-popover>
          </template>
          <div class="gl-display-flex gl-flex-direction-column">
            <span
              class="gl-font-weight-bold gl-font-size-h2 gl-mb-2"
              data-testid="insights-queued-card-data"
            >
              {{ queuedDurationDisplay }}
            </span>
            <gl-link
              :href="longestQueuedJob.detailedStatus.detailsPath"
              data-testid="insights-queued-card-link"
            >
              {{ longestQueuedJob.name }}
            </gl-link>
          </div>
        </gl-card>
        <gl-card class="gl-w-half gl-text-center" data-testid="insights-executed-card">
          <template #header>
            <span class="gl-font-weight-bold">{{ $options.i18n.executedCardHeader }}</span>
            <help-popover>
              {{ $options.i18n.executedCardHelp }}
            </help-popover>
          </template>
          <div class="gl-display-flex gl-flex-direction-column">
            <span
              class="gl-font-weight-bold gl-font-size-h2 gl-mb-2"
              data-testid="insights-executed-card-data"
            >
              {{ lastExecutedJob.name }}
            </span>
            <gl-link
              :href="lastExecutedJob.detailedStatus.detailsPath"
              data-testid="insights-executed-card-link"
            >
              {{ $options.i18n.viewDependency }}
            </gl-link>
          </div>
        </gl-card>
      </div>

      <div class="gl-mt-7">
        <span class="gl-font-weight-bold">{{ $options.i18n.slowJobsTitle }}</span>
        <div
          v-for="job in slowestFiveJobs"
          :key="job.name"
          class="gl-display-flex gl-justify-content-space-between gl-mb-3 gl-mt-3 gl-p-4 gl-border-t-1 gl-border-t-solid gl-border-b-0 gl-border-b-solid gl-border-gray-100"
        >
          <span data-testid="insights-slow-job-stage">{{ job.stage.name }}</span>
          <gl-link :href="job.detailedStatus.detailsPath" data-testid="insights-slow-job-link">{{
            job.name
          }}</gl-link>
        </div>
      </div>
    </template>
  </gl-modal>
</template>
