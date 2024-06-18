<script>
import { GlButton, GlIcon, GlLink, GlTooltip } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { BRIDGE_KIND } from '~/ci/pipeline_details/graph/constants';
import RetryMrFailedJobMutation from '~/ci/merge_requests/graphql/mutations/retry_mr_failed_job.mutation.graphql';

export default {
  components: {
    CiIcon,
    GlButton,
    GlIcon,
    GlLink,
    GlTooltip,
  },
  directives: {
    SafeHtml,
  },
  props: {
    job: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isHovered: false,
      isJobLogVisible: false,
      isLoadingAction: false,
    };
  },
  computed: {
    canReadBuild() {
      return this.job.userPermissions.readBuild;
    },
    canRetryJob() {
      return this.job.retryable && this.job.userPermissions.updateBuild && !this.isBridgeJob;
    },
    isBridgeJob() {
      return this.job.kind === BRIDGE_KIND;
    },
    jobChevronName() {
      return this.isJobLogVisible ? 'chevron-down' : 'chevron-right';
    },
    jobTrace() {
      if (this.canReadBuild) {
        return this.job?.trace?.htmlSummary || this.$options.i18n.noTraceText;
      }

      return this.$options.i18n.cannotReadBuild;
    },
    parsedJobId() {
      return getIdFromGraphQLId(this.job.id);
    },
    tooltipErrorText() {
      return this.isBridgeJob
        ? this.$options.i18n.cannotRetryTrigger
        : this.$options.i18n.cannotRetry;
    },
    tooltipText() {
      return sprintf(this.$options.i18n.jobActionTooltipText, { jobName: this.job.name });
    },
  },
  methods: {
    setActiveRow() {
      this.isHovered = true;
    },
    resetActiveRow() {
      this.isHovered = false;
    },
    async retryJob() {
      try {
        this.isLoadingAction = true;

        const {
          data: {
            jobRetry: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: RetryMrFailedJobMutation,
          variables: { id: this.job.id },
        });

        if (errors.length > 0) {
          throw new Error(errors[0]);
        }

        this.$emit('job-retried', this.job.name);
      } catch (error) {
        createAlert({ message: error?.message || this.$options.i18n.retryError });
      } finally {
        this.isLoadingAction = false;
      }
    },
    toggleJobLog(event) {
      // Do not toggle the log visibility when clicking on a link
      if (event.target.tagName === 'A') {
        return;
      }
      this.isJobLogVisible = !this.isJobLogVisible;
    },
  },
  i18n: {
    cannotReadBuild: s__("Job|You do not have permission to read this job's log."),
    cannotRetry: s__('Job|You do not have permission to run this job again.'),
    cannotRetryTrigger: s__('Job|You cannot rerun trigger jobs from this list.'),
    jobActionTooltipText: s__('Pipelines|Retry %{jobName} Job'),
    noTraceText: s__('Job|No job log'),
    retry: __('Retry'),
    retryError: __('There was an error while retrying this job'),
  },
};
</script>
<template>
  <div class="container-fluid gl-grid-rows-auto">
    <div
      class="row gl-my-3 gl-cursor-pointer gl-display-flex gl-align-items-center"
      :aria-pressed="isJobLogVisible"
      role="button"
      tabindex="0"
      data-testid="widget-row"
      @click="toggleJobLog"
      @keyup.enter="toggleJobLog"
      @keyup.space="toggleJobLog"
      @mouseover="setActiveRow"
      @mouseout="resetActiveRow"
    >
      <div class="col-6 gl-text-gray-900 gl-font-bold gl-text-left">
        <gl-icon :name="jobChevronName" />
        <ci-icon :status="job.detailedStatus" />
        {{ job.name }}
      </div>
      <div class="col-2 gl-text-left">{{ job.stage.name }}</div>
      <div class="col-2 gl-text-left">
        <gl-link :href="job.detailedStatus.detailsPath">#{{ parsedJobId }}</gl-link>
      </div>
      <gl-tooltip v-if="!canRetryJob" :target="() => $refs.retryBtn" placement="top">
        {{ tooltipErrorText }}
      </gl-tooltip>
      <div class="col-2 gl-text-right">
        <span ref="retryBtn">
          <gl-button
            :disabled="!canRetryJob"
            icon="retry"
            category="tertiary"
            :loading="isLoadingAction"
            :title="$options.i18n.retry"
            :aria-label="$options.i18n.retry"
            @click.stop="retryJob"
          />
        </span>
      </div>
    </div>
    <div v-if="isJobLogVisible" class="row">
      <pre
        v-safe-html="jobTrace"
        class="gl-bg-gray-900 gl-text-white gl-w-full"
        data-testid="job-log"
      ></pre>
    </div>
  </div>
</template>
