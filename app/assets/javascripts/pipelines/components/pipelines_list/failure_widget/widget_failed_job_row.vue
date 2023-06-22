<script>
import { GlButton, GlCollapse, GlIcon, GlLink, GlTooltip } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { __, s__, sprintf } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiIcon from '~/vue_shared/components/ci_icon.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import RetryMrFailedJobMutation from '../../../graphql/mutations/retry_mr_failed_job.mutation.graphql';

export default {
  components: {
    CiIcon,
    GlButton,
    GlCollapse,
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
    activeClass() {
      return this.isHovered ? 'gl-bg-gray-50' : '';
    },
    canReadBuild() {
      return this.job.userPermissions.readBuild;
    },
    canRetryJob() {
      return this.job.retryable && this.job.userPermissions.updateBuild;
    },
    isVisibleId() {
      return `log-${this.isJobLogVisible ? 'is-visible' : 'is-hidden'}`;
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
    cannotReadBuild: s__("Job|You do not have permission to read this job's log"),
    cannotRetry: s__('Job|You do not have permission to retry this job'),
    jobActionTooltipText: s__('Pipelines|Retry %{jobName} Job'),
    noTraceText: s__('Job|No job log'),
    retry: __('Retry'),
    retryError: __('There was an error while retrying this job'),
  },
};
</script>
<template>
  <div class="container-fluid gl-grid-tpl-rows-auto">
    <div
      class="row gl-py-4 gl-cursor-pointer gl-display-flex gl-align-items-center"
      :class="activeClass"
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
      <div class="col-6 gl-text-gray-900 gl-font-weight-bold gl-text-left">
        <gl-icon :name="jobChevronName" class="gl-fill-blue-500" />
        <ci-icon :status="job.detailedStatus" />
        {{ job.name }}
      </div>
      <div class="col-2 gl-text-left">{{ job.stage.name }}</div>
      <div class="col-2 gl-text-left">
        <gl-link :href="job.webPath">#{{ parsedJobId }}</gl-link>
      </div>
      <gl-tooltip v-if="!canRetryJob" :target="() => $refs.retryBtn" placement="top">
        {{ $options.i18n.cannotRetry }}
      </gl-tooltip>
      <div class="col-2 gl-text-left">
        <span ref="retryBtn">
          <gl-button
            :disabled="!canRetryJob"
            icon="retry"
            :loading="isLoadingAction"
            :title="$options.i18n.retry"
            :aria-label="$options.i18n.retry"
            @click.stop="retryJob"
          />
        </span>
      </div>
    </div>
    <div class="row">
      <gl-collapse :visible="isJobLogVisible" class="gl-w-full">
        <pre
          v-safe-html="jobTrace"
          class="gl-bg-gray-900 gl-text-white"
          :data-testid="isVisibleId"
        ></pre>
      </gl-collapse>
    </div>
  </div>
</template>
