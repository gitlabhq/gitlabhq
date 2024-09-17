<script>
import { GlButton, GlLink, GlTooltip } from '@gitlab/ui';
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
      isLoadingAction: false,
    };
  },
  computed: {
    canRetryJob() {
      return this.job.retryable && this.job.userPermissions.updateBuild && !this.isBridgeJob;
    },
    detailsPath() {
      return this.job?.detailedStatus?.detailsPath;
    },
    isBridgeJob() {
      return this.job.kind === BRIDGE_KIND;
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
  },
  i18n: {
    cannotReadBuild: s__("Job|You do not have permission to read this job's log."),
    cannotRetry: s__('Job|You do not have permission to run this job again.'),
    cannotRetryTrigger: s__('Job|You cannot rerun trigger jobs from this list.'),
    jobActionTooltipText: s__('Pipelines|Retry %{jobName} Job'),
    retry: __('Retry'),
    retryError: __('There was an error while retrying this job'),
  },
};
</script>
<template>
  <div class="container-fluid gl-my-1 gl-grid-rows-auto">
    <div class="row gl-flex gl-items-center" data-testid="widget-row">
      <div class="align-items-center col-6 gl-flex gl-font-bold gl-text-gray-900">
        <ci-icon :status="job.detailedStatus" />
        <gl-link
          class="gl-ml-2 !gl-text-gray-900 !gl-no-underline"
          :href="detailsPath"
          data-testid="job-name-link"
          >{{ job.name }}</gl-link
        >
      </div>
      <div class="col-2 gl-flex gl-items-center" data-testid="job-stage-name">
        {{ job.stage.name }}
      </div>
      <div class="col-2 gl-flex gl-items-center">
        <gl-link :href="detailsPath" data-testid="job-id-link">#{{ parsedJobId }}</gl-link>
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
            data-testid="retry-button"
            @click.stop="retryJob"
          />
        </span>
      </div>
    </div>
  </div>
</template>
