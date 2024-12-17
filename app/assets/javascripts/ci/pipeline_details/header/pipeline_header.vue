<script>
import { GlAlert, GlIcon, GlLink, GlLoadingIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { BUTTON_TOOLTIP_RETRY, BUTTON_TOOLTIP_CANCEL } from '~/ci/constants';
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';
import { setUrlFragment, visitUrl } from '~/lib/utils/url_utility';
import { __, n__, sprintf, formatNumber } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { reportToSentry } from '~/ci/utils';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { LOAD_FAILURE, POST_FAILURE, DELETE_FAILURE, DEFAULT } from '../constants';
import cancelPipelineMutation from '../graphql/mutations/cancel_pipeline.mutation.graphql';
import deletePipelineMutation from '../graphql/mutations/delete_pipeline.mutation.graphql';
import retryPipelineMutation from '../graphql/mutations/retry_pipeline.mutation.graphql';
import { getQueryHeaders } from '../graph/utils';
import { POLL_INTERVAL } from '../graph/constants';
import { MERGE_TRAIN_EVENT_TYPE } from './constants';
import HeaderActions from './components/header_actions.vue';
import HeaderBadges from './components/header_badges.vue';
import getPipelineQuery from './graphql/queries/get_pipeline_header_data.query.graphql';

export default {
  name: 'PipelineHeader',
  BUTTON_TOOLTIP_RETRY,
  BUTTON_TOOLTIP_CANCEL,
  pipelineCancel: 'pipelineCancel',
  pipelineRetry: 'pipelineRetry',
  finishedStatuses: ['FAILED', 'SUCCESS', 'CANCELED'],
  components: {
    CiIcon,
    ClipboardButton,
    GlAlert,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    HeaderActions,
    HeaderBadges,
    TimeAgoTooltip,
    PipelineAccountVerificationAlert: () =>
      import('ee_component/vue_shared/components/pipeline_account_verification_alert.vue'),
    HeaderMergeTrainsLink: () =>
      import('ee_component/ci/pipeline_details/header/components/header_merge_trains_link.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  errorTexts: {
    [LOAD_FAILURE]: __('We are currently unable to fetch data for the pipeline header.'),
    [POST_FAILURE]: __('An error occurred while making the request.'),
    [DELETE_FAILURE]: __('An error occurred while deleting the pipeline.'),
    [DEFAULT]: __('An unknown error occurred.'),
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
      error(error) {
        this.reportFailure(LOAD_FAILURE);
        reportToSentry(this.$options.name, error);
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
    commitSha() {
      return this.pipeline?.commit?.sha || '';
    },
    commitPath() {
      return this.pipeline?.commit?.webPath || '';
    },
    commitTitle() {
      return this.pipeline?.commit?.title || '';
    },
    totalJobsText() {
      const totalJobs = this.pipeline?.totalJobs || 0;

      return sprintf(n__('%{jobs} job', '%{jobs} jobs', totalJobs), {
        jobs: totalJobs,
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
    isMergeTrainPipeline() {
      return this.pipeline.mergeRequestEventType === MERGE_TRAIN_EVENT_TYPE;
    },
  },
  methods: {
    reportFailure(errorType, errorMessages = []) {
      this.failureType = errorType;
      this.failureMessages = errorMessages;
    },
    async postPipelineAction(name, mutation, id) {
      try {
        const {
          data: {
            [name]: { errors },
          },
        } = await this.$apollo.mutate({
          mutation,
          variables: { id },
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
      } catch (error) {
        this.isRetrying = false;

        this.reportFailure(POST_FAILURE);
        reportToSentry(this.$options.name, error);
      }
    },
    cancelPipeline(id) {
      this.isCanceling = true;
      this.postPipelineAction(this.$options.pipelineCancel, cancelPipelineMutation, id);
    },
    retryPipeline(id) {
      this.isRetrying = true;
      this.postPipelineAction(this.$options.pipelineRetry, retryPipelineMutation, id);
    },
    async deletePipeline(id) {
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
            id,
          },
        });

        if (errors.length > 0) {
          this.reportFailure(DELETE_FAILURE, errors);
          this.isDeleting = false;
        } else {
          visitUrl(setUrlFragment(this.paths.pipelinesPath, 'delete_success'));
        }
      } catch (error) {
        this.$apollo.queries.pipeline.startPolling(POLL_INTERVAL);

        this.isDeleting = false;

        this.reportFailure(DELETE_FAILURE);
        reportToSentry(this.$options.name, error);
      }
    },
  },
};
</script>

<template>
  <div class="gl-my-4" data-testid="pipeline-header">
    <gl-alert
      v-if="hasError"
      class="gl-mb-4"
      :title="failure.text"
      :variant="failure.variant"
      :dismissible="false"
      data-testid="error-alert"
    >
      <div v-for="(failureMessage, index) in failureMessages" :key="`failure-message-${index}`">
        {{ failureMessage }}
      </div>
    </gl-alert>

    <gl-loading-icon v-if="loading" class="gl-text-left" size="lg" />

    <div v-else class="gl-flex gl-flex-wrap gl-justify-between">
      <div>
        <h3 v-if="pipelineName" class="gl-mb-3 gl-mt-0" data-testid="pipeline-name">
          {{ pipelineName }}
        </h3>
        <h3 v-else class="gl-mb-3 gl-mt-0" data-testid="pipeline-commit-title">
          {{ commitTitle }}
        </h3>
        <div>
          <ci-icon :status="detailedStatus" show-status-text :show-link="false" class="gl-mb-3" />
          <div class="gl-mb-3 gl-ml-2 gl-inline-block gl-h-6">
            <gl-link
              v-if="user"
              :href="user.webUrl"
              class="js-user-link gl-inline-block gl-font-bold gl-text-default"
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
          <div class="gl-mb-3 gl-inline-block">
            <clipboard-button
              :text="commitSha"
              category="tertiary"
              :title="__('Copy commit SHA')"
              data-testid="commit-copy-sha"
              size="small"
            />
            <time-ago-tooltip
              v-if="inProgress"
              :time="pipeline.createdAt"
              data-testid="pipeline-created-time-ago"
            />
            <template v-if="isFinished">
              <time-ago-tooltip
                :time="pipeline.createdAt"
                data-testid="pipeline-finished-created-time-ago"
              />, {{ s__('Pipelines|finished') }}
              <time-ago-tooltip
                :time="pipeline.finishedAt"
                data-testid="pipeline-finished-time-ago"
              />
            </template>
          </div>
        </div>
        <div v-safe-html="refText" class="gl-mb-3" data-testid="pipeline-ref-text"></div>
        <div>
          <header-badges :pipeline="pipeline" />

          <div class="gl-inline-block">
            <span
              v-gl-tooltip
              :title="s__('Pipelines|Total number of jobs for the pipeline')"
              class="gl-ml-2"
              data-testid="total-jobs"
            >
              <gl-icon name="pipeline" />
              {{ totalJobsText }}
            </span>
            <span
              v-if="showComputeMinutes"
              v-gl-tooltip
              :title="s__('Pipelines|Total amount of compute minutes used for the pipeline')"
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
        <div v-if="isMergeTrainPipeline" class="gl-mt-2">
          <header-merge-trains-link />
        </div>
      </div>

      <header-actions
        :pipeline="pipeline"
        :is-retrying="isRetrying"
        :is-canceling="isCanceling"
        :is-deleting="isDeleting"
        @retryPipeline="retryPipeline($event)"
        @cancelPipeline="cancelPipeline($event)"
        @deletePipeline="deletePipeline($event)"
      />
    </div>

    <pipeline-account-verification-alert class="gl-mt-4" />
  </div>
</template>
