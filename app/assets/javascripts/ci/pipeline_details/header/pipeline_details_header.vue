<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlIcon,
  GlLink,
  GlLoadingIcon,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlTooltipDirective,
} from '@gitlab/ui';
import { BUTTON_TOOLTIP_RETRY, BUTTON_TOOLTIP_CANCEL } from '~/ci/constants';
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';
import { setUrlFragment, redirectTo } from '~/lib/utils/url_utility'; // eslint-disable-line import/no-deprecated
import { __, s__, sprintf, formatNumber } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { LOAD_FAILURE, POST_FAILURE, DELETE_FAILURE, DEFAULT } from '../constants';
import cancelPipelineMutation from '../graphql/mutations/cancel_pipeline.mutation.graphql';
import deletePipelineMutation from '../graphql/mutations/delete_pipeline.mutation.graphql';
import retryPipelineMutation from '../graphql/mutations/retry_pipeline.mutation.graphql';
import { getQueryHeaders } from '../graph/utils';
import getPipelineQuery from './graphql/queries/get_pipeline_header_data.query.graphql';
import {
  DELETE_MODAL_ID,
  POLL_INTERVAL,
  DETACHED_EVENT_TYPE,
  AUTO_DEVOPS_SOURCE,
  SCHEDULE_SOURCE,
  MERGE_TRAIN_EVENT_TYPE,
  MERGED_RESULT_EVENT_TYPE,
} from './constants';

export default {
  name: 'PipelineDetailsHeader',
  BUTTON_TOOLTIP_RETRY,
  BUTTON_TOOLTIP_CANCEL,
  pipelineCancel: 'pipelineCancel',
  pipelineRetry: 'pipelineRetry',
  finishedStatuses: ['FAILED', 'SUCCESS', 'CANCELED'],
  components: {
    CiIcon,
    ClipboardButton,
    GlAlert,
    GlBadge,
    GlButton,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlModal,
    GlSprintf,
    TimeAgoTooltip,
  },
  directives: {
    GlModal: GlModalDirective,
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  i18n: {
    scheduleBadgeText: s__('Pipelines|Scheduled'),
    scheduleBadgeTooltip: __('This pipeline was created by a schedule'),
    triggerBadgeText: __('trigger token'),
    triggerBadgeTooltip: __(
      'This pipeline was created by an API call authenticated with a trigger token',
    ),
    childBadgeText: s__('Pipelines|Child pipeline (%{linkStart}parent%{linkEnd})'),
    childBadgeTooltip: __('This is a child pipeline within the parent pipeline'),
    latestBadgeText: s__('Pipelines|latest'),
    latestBadgeTooltip: __('Latest pipeline for the most recent commit on this branch'),
    mergeTrainBadgeText: s__('Pipelines|merge train'),
    mergeTrainBadgeTooltip: s__(
      'Pipelines|This pipeline ran on the contents of the merge request combined with the contents of all other merge requests queued for merging into the target branch.',
    ),
    invalidBadgeText: s__('Pipelines|yaml invalid'),
    failedBadgeText: s__('Pipelines|error'),
    autoDevopsBadgeText: s__('Pipelines|Auto DevOps'),
    autoDevopsBadgeTooltip: __(
      'This pipeline makes use of a predefined CI/CD configuration enabled by Auto DevOps.',
    ),
    detachedBadgeText: s__('Pipelines|merge request'),
    detachedBadgeTooltip: s__(
      "Pipelines|This pipeline ran on the contents of the merge request's source branch, not the target branch.",
    ),
    mergedResultsBadgeText: s__('Pipelines|merged results'),
    mergedResultsBadgeTooltip: s__(
      'Pipelines|This pipeline ran on the contents of the merge request combined with the contents of the target branch.',
    ),
    stuckBadgeText: s__('Pipelines|stuck'),
    stuckBadgeTooltip: s__('Pipelines|This pipeline is stuck'),
    computeMinutesTooltip: s__('Pipelines|Total amount of compute minutes used for the pipeline'),
    totalJobsTooltip: s__('Pipelines|Total number of jobs for the pipeline'),
    retryPipelineText: __('Retry'),
    cancelPipelineText: __('Cancel pipeline'),
    deletePipelineText: __('Delete'),
    clipboardTooltip: __('Copy commit SHA'),
    createdText: s__('Pipelines|created'),
    finishedText: s__('Pipelines|finished'),
  },
  errorTexts: {
    [LOAD_FAILURE]: __('We are currently unable to fetch data for the pipeline header.'),
    [POST_FAILURE]: __('An error occurred while making the request.'),
    [DELETE_FAILURE]: __('An error occurred while deleting the pipeline.'),
    [DEFAULT]: __('An unknown error occurred.'),
  },
  modal: {
    id: DELETE_MODAL_ID,
    title: __('Delete pipeline'),
    deleteConfirmationText: __(
      'Are you sure you want to delete this pipeline? Doing so will expire all pipeline caches and delete all related objects, such as builds, logs, artifacts, and triggers. This action cannot be undone.',
    ),
    actionPrimary: {
      text: __('Delete pipeline'),
      attributes: {
        variant: 'danger',
      },
    },
    actionCancel: {
      text: __('Cancel'),
    },
  },
  inject: {
    graphqlResourceEtag: {
      default: '',
    },
    paths: {
      default: {},
    },
    pipelineIid: {
      default: '',
    },
  },
  props: {
    yamlErrors: {
      type: String,
      required: false,
      default: '',
    },
    trigger: {
      type: Boolean,
      required: true,
    },
  },
  apollo: {
    pipeline: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getPipelineQuery,
      variables() {
        return {
          fullPath: this.paths.fullProject,
          iid: this.pipelineIid,
        };
      },
      update(data) {
        return data.project.pipeline;
      },
      error() {
        this.reportFailure(LOAD_FAILURE);
      },
      pollInterval: POLL_INTERVAL,
      watchLoading(isLoading) {
        if (!isLoading) {
          // To ensure apollo has updated the cache,
          // we only remove the loading state in sync with GraphQL
          this.isCanceling = false;
          this.isRetrying = false;
        }
      },
    },
  },
  data() {
    return {
      pipeline: null,
      failureMessages: [],
      failureType: null,
      isCanceling: false,
      isRetrying: false,
      isDeleting: false,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.pipeline.loading;
    },
    hasError() {
      return this.failureType;
    },
    hasPipelineData() {
      return Boolean(this.pipeline);
    },
    isLoadingInitialQuery() {
      return this.$apollo.queries.pipeline.loading && !this.hasPipelineData;
    },
    detailedStatus() {
      return this.pipeline?.detailedStatus || {};
    },
    status() {
      return this.pipeline?.status;
    },
    isFinished() {
      return this.$options.finishedStatuses.includes(this.status);
    },
    shouldRenderContent() {
      return !this.isLoadingInitialQuery && this.hasPipelineData;
    },
    failure() {
      switch (this.failureType) {
        case LOAD_FAILURE:
          return {
            text: this.$options.errorTexts[LOAD_FAILURE],
            variant: 'danger',
          };
        case POST_FAILURE:
          return {
            text: this.$options.errorTexts[POST_FAILURE],
            variant: 'danger',
          };
        case DELETE_FAILURE:
          return {
            text: this.$options.errorTexts[DELETE_FAILURE],
            variant: 'danger',
          };
        default:
          return {
            text: this.$options.errorTexts[DEFAULT],
            variant: 'danger',
          };
      }
    },
    user() {
      return this.pipeline?.user;
    },
    userId() {
      return getIdFromGraphQLId(this.user?.id);
    },
    shortId() {
      return this.pipeline?.commit?.shortId || '';
    },
    commitPath() {
      return this.pipeline?.commit?.webPath || '';
    },
    commitTitle() {
      return this.pipeline?.commit?.title || '';
    },
    totalJobsText() {
      return sprintf(__('%{jobs} Jobs'), {
        jobs: this.pipeline?.totalJobs || 0,
      });
    },
    triggeredText() {
      return sprintf(__('created pipeline for commit %{linkStart}%{shortId}%{linkEnd}'), {
        shortId: this.shortId,
      });
    },
    inProgress() {
      return this.status === 'RUNNING';
    },
    duration() {
      return this.pipeline?.duration || 0;
    },
    showDuration() {
      return this.duration && this.isFinished;
    },
    durationFormatted() {
      return timeIntervalInWords(this.duration);
    },
    queuedDuration() {
      return this.pipeline?.queuedDuration || 0;
    },
    inProgressText() {
      return sprintf(__('In progress, queued for %{queuedDuration} seconds'), {
        queuedDuration: formatNumber(this.queuedDuration),
      });
    },
    durationText() {
      return sprintf(__('%{duration}, queued for %{queuedDuration} seconds'), {
        duration: this.durationFormatted,
        queuedDuration: formatNumber(this.queuedDuration),
      });
    },
    canRetryPipeline() {
      const { retryable, userPermissions } = this.pipeline;

      return retryable && userPermissions.updatePipeline;
    },
    canCancelPipeline() {
      const { cancelable, userPermissions } = this.pipeline;

      return cancelable && userPermissions.cancelPipeline;
    },
    computeMinutes() {
      return this.pipeline?.computeMinutes;
    },
    showComputeMinutes() {
      return this.isFinished && this.computeMinutes;
    },
    pipelineName() {
      return this.pipeline?.name;
    },
    refText() {
      return this.pipeline?.refText;
    },
    triggeredByPath() {
      return this.pipeline?.triggeredByPath;
    },
    mergeRequestEventType() {
      return this.pipeline.mergeRequestEventType;
    },
    isMergeTrainPipeline() {
      return this.mergeRequestEventType === MERGE_TRAIN_EVENT_TYPE;
    },
    isMergedResultsPipeline() {
      return this.mergeRequestEventType === MERGED_RESULT_EVENT_TYPE;
    },
    isDetachedPipeline() {
      return this.mergeRequestEventType === DETACHED_EVENT_TYPE;
    },
    isAutoDevopsPipeline() {
      return this.pipeline.configSource === AUTO_DEVOPS_SOURCE;
    },
    isScheduledPipeline() {
      return this.pipeline.source === SCHEDULE_SOURCE;
    },
    isInvalidPipeline() {
      return Boolean(this.yamlErrors);
    },
    failureReason() {
      return this.pipeline.failureReason;
    },
    badges() {
      return {
        schedule: this.isScheduledPipeline,
        trigger: this.trigger,
        invalid: this.isInvalidPipeline,
        child: this.pipeline.child,
        latest: this.pipeline.latest,
        mergeTrainPipeline: this.isMergeTrainPipeline,
        mergedResultsPipeline: this.isMergedResultsPipeline,
        detached: this.isDetachedPipeline,
        failed: Boolean(this.failureReason),
        autoDevops: this.isAutoDevopsPipeline,
        stuck: this.pipeline.stuck,
      };
    },
  },
  methods: {
    reportFailure(errorType, errorMessages = []) {
      this.failureType = errorType;
      this.failureMessages = errorMessages;
    },
    async postPipelineAction(name, mutation) {
      try {
        const {
          data: {
            [name]: { errors },
          },
        } = await this.$apollo.mutate({
          mutation,
          variables: { id: this.pipeline.id },
        });

        if (errors.length > 0) {
          this.isRetrying = false;

          this.reportFailure(POST_FAILURE, errors);
        } else {
          await this.$apollo.queries.pipeline.refetch();
          if (!this.isFinished) {
            this.$apollo.queries.pipeline.startPolling(POLL_INTERVAL);
          }
        }
      } catch {
        this.isRetrying = false;

        this.reportFailure(POST_FAILURE);
      }
    },
    cancelPipeline() {
      this.isCanceling = true;
      this.postPipelineAction(this.$options.pipelineCancel, cancelPipelineMutation);
    },
    retryPipeline() {
      this.isRetrying = true;
      this.postPipelineAction(this.$options.pipelineRetry, retryPipelineMutation);
    },
    async deletePipeline() {
      this.isDeleting = true;
      this.$apollo.queries.pipeline.stopPolling();

      try {
        const {
          data: {
            pipelineDestroy: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: deletePipelineMutation,
          variables: {
            id: this.pipeline.id,
          },
        });

        if (errors.length > 0) {
          this.reportFailure(DELETE_FAILURE, errors);
          this.isDeleting = false;
        } else {
          redirectTo(setUrlFragment(this.paths.pipelinesPath, 'delete_success')); // eslint-disable-line import/no-deprecated
        }
      } catch {
        this.$apollo.queries.pipeline.startPolling(POLL_INTERVAL);
        this.reportFailure(DELETE_FAILURE);
        this.isDeleting = false;
      }
    },
  },
};
</script>

<template>
  <div class="gl-my-4" data-testid="pipeline-details-header">
    <gl-alert
      v-if="hasError"
      class="gl-mb-4"
      :title="failure.text"
      :variant="failure.variant"
      :dismissible="false"
    >
      <div v-for="(failureMessage, index) in failureMessages" :key="`failure-message-${index}`">
        {{ failureMessage }}
      </div>
    </gl-alert>
    <gl-loading-icon v-if="loading" class="gl-text-left" size="lg" />
    <div v-else class="gl-display-flex gl-justify-content-space-between gl-flex-wrap">
      <div>
        <h3 v-if="pipelineName" class="gl-mt-0 gl-mb-3" data-testid="pipeline-name">
          {{ pipelineName }}
        </h3>
        <h3 v-else class="gl-mt-0 gl-mb-3" data-testid="pipeline-commit-title">
          {{ commitTitle }}
        </h3>
        <div>
          <ci-icon :status="detailedStatus" show-status-text :show-link="false" class="gl-mb-3" />
          <div class="gl-ml-2 gl-mb-3 gl-display-inline-block gl-h-6">
            <gl-link
              v-if="user"
              :href="user.webUrl"
              class="gl-display-inline-block gl-text-gray-900 gl-font-weight-bold js-user-link"
              :data-user-id="userId"
              :data-username="user.username"
              data-testid="pipeline-user-link"
            >
              {{ user.name }}
            </gl-link>
            <gl-sprintf :message="triggeredText">
              <template #link="{ content }">
                <gl-link
                  :href="commitPath"
                  class="commit-sha-container"
                  data-testid="commit-link"
                  target="_blank"
                >
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </div>
          <div class="gl-display-inline-block gl-mb-3">
            <clipboard-button
              :text="shortId"
              category="tertiary"
              :title="$options.i18n.clipboardTooltip"
              size="small"
            />
            <span v-if="inProgress" data-testid="pipeline-created-time-ago">
              {{ $options.i18n.createdText }}
              <time-ago-tooltip :time="pipeline.createdAt" />
            </span>
            <span v-if="isFinished" data-testid="pipeline-finished-time-ago">
              {{ $options.i18n.finishedText }}
              <time-ago-tooltip :time="pipeline.finishedAt" />
            </span>
          </div>
        </div>
        <div v-safe-html="refText" class="gl-mb-3" data-testid="pipeline-ref-text"></div>
        <div>
          <div class="gl-display-inline-block gl-mb-3">
            <gl-badge
              v-if="badges.schedule"
              v-gl-tooltip
              :title="$options.i18n.scheduleBadgeTooltip"
              variant="info"
              size="sm"
            >
              {{ $options.i18n.scheduleBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="badges.trigger"
              v-gl-tooltip
              :title="$options.i18n.triggerBadgeTooltip"
              variant="info"
              size="sm"
            >
              {{ $options.i18n.triggerBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="badges.child"
              v-gl-tooltip
              :title="$options.i18n.childBadgeTooltip"
              variant="info"
              size="sm"
            >
              <gl-sprintf :message="$options.i18n.childBadgeText">
                <template #link="{ content }">
                  <gl-link :href="triggeredByPath" target="_blank">
                    {{ content }}
                  </gl-link>
                </template>
              </gl-sprintf>
            </gl-badge>
            <gl-badge
              v-if="badges.latest"
              v-gl-tooltip
              :title="$options.i18n.latestBadgeTooltip"
              variant="success"
              size="sm"
            >
              {{ $options.i18n.latestBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="badges.mergeTrainPipeline"
              v-gl-tooltip
              :title="$options.i18n.mergeTrainBadgeTooltip"
              variant="info"
              size="sm"
            >
              {{ $options.i18n.mergeTrainBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="badges.invalid"
              v-gl-tooltip
              :title="yamlErrors"
              variant="danger"
              size="sm"
            >
              {{ $options.i18n.invalidBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="badges.failed"
              v-gl-tooltip
              :title="failureReason"
              variant="danger"
              size="sm"
            >
              {{ $options.i18n.failedBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="badges.autoDevops"
              v-gl-tooltip
              :title="$options.i18n.autoDevopsBadgeTooltip"
              variant="info"
              size="sm"
            >
              {{ $options.i18n.autoDevopsBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="badges.detached"
              v-gl-tooltip
              :title="$options.i18n.detachedBadgeTooltip"
              variant="info"
              size="sm"
            >
              {{ $options.i18n.detachedBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="badges.mergedResultsPipeline"
              v-gl-tooltip
              :title="$options.i18n.mergedResultsBadgeTooltip"
              variant="info"
              size="sm"
            >
              {{ $options.i18n.mergedResultsBadgeText }}
            </gl-badge>
            <gl-badge
              v-if="badges.stuck"
              v-gl-tooltip
              :title="$options.i18n.stuckBadgeTooltip"
              variant="warning"
              size="sm"
            >
              {{ $options.i18n.stuckBadgeText }}
            </gl-badge>
          </div>
          <div class="gl-display-inline-block">
            <span
              v-gl-tooltip
              :title="$options.i18n.totalJobsTooltip"
              class="gl-ml-2"
              data-testid="total-jobs"
            >
              <gl-icon name="pipeline" />
              {{ totalJobsText }}
            </span>
            <span
              v-if="showComputeMinutes"
              v-gl-tooltip
              :title="$options.i18n.computeMinutesTooltip"
              class="gl-ml-2"
              data-testid="compute-minutes"
            >
              <gl-icon name="quota" />
              {{ computeMinutes }}
            </span>
            <span v-if="inProgress" class="gl-ml-2" data-testid="pipeline-running-text">
              <gl-icon name="timer" />
              {{ inProgressText }}
            </span>
            <span v-if="showDuration" class="gl-ml-2" data-testid="pipeline-duration-text">
              <gl-icon name="timer" />
              {{ durationText }}
            </span>
          </div>
        </div>
      </div>
      <div class="gl-mt-5 gl-lg-mt-0 gl-display-flex gl-align-items-flex-start gl-gap-3">
        <gl-button
          v-if="canRetryPipeline"
          v-gl-tooltip
          :aria-label="$options.BUTTON_TOOLTIP_RETRY"
          :title="$options.BUTTON_TOOLTIP_RETRY"
          :loading="isRetrying"
          :disabled="isRetrying"
          variant="confirm"
          data-testid="retry-pipeline"
          class="js-retry-button"
          @click="retryPipeline()"
        >
          {{ $options.i18n.retryPipelineText }}
        </gl-button>

        <gl-button
          v-if="canCancelPipeline"
          v-gl-tooltip
          :aria-label="$options.BUTTON_TOOLTIP_CANCEL"
          :title="$options.BUTTON_TOOLTIP_CANCEL"
          :loading="isCanceling"
          :disabled="isCanceling"
          variant="danger"
          data-testid="cancel-pipeline"
          @click="cancelPipeline()"
        >
          {{ $options.i18n.cancelPipelineText }}
        </gl-button>

        <gl-button
          v-if="pipeline.userPermissions.destroyPipeline"
          v-gl-modal="$options.modal.id"
          :loading="isDeleting"
          :disabled="isDeleting"
          variant="danger"
          category="secondary"
          data-testid="delete-pipeline"
        >
          {{ $options.i18n.deletePipelineText }}
        </gl-button>
      </div>
    </div>
    <gl-modal
      :modal-id="$options.modal.id"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @primary="deletePipeline()"
    >
      <p>
        {{ $options.modal.deleteConfirmationText }}
      </p>
    </gl-modal>
  </div>
</template>
