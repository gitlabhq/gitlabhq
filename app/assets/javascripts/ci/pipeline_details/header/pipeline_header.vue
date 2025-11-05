<script>
import { GlAlert, GlIcon, GlLink, GlLoadingIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import DuoWorkflowAction from 'ee_component/ai/components/duo_workflow_action.vue';
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';
import { setUrlFragment, visitUrl } from '~/lib/utils/url_utility';
import { __, n__, sprintf, formatNumber } from '~/locale';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { reportToSentry } from '~/ci/utils';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { FIX_PIPELINE_AGENT_PRIVILEGES } from '~/duo_agent_platform/constants';
import { LOAD_FAILURE, POST_FAILURE, DELETE_FAILURE, DEFAULT } from '../constants';
import cancelPipelineMutation from '../graphql/mutations/cancel_pipeline.mutation.graphql';
import deletePipelineMutation from '../graphql/mutations/delete_pipeline.mutation.graphql';
import retryPipelineMutation from '../graphql/mutations/retry_pipeline.mutation.graphql';
import { getQueryHeaders } from '../graph/utils';
import pipelineHeaderStatusUpdatedSubscription from './graphql/subscriptions/pipeline_header_status_updated.subscription.graphql';
import { MERGE_TRAIN_EVENT_TYPE } from './constants';
import HeaderActions from './components/header_actions.vue';
import HeaderBadges from './components/header_badges.vue';
import getPipelineQuery from './graphql/queries/get_pipeline_header_data.query.graphql';

const finishedStatuses = ['FAILED', 'SUCCESS', 'CANCELED'];
const pipelineCancel = 'pipelineCancel';
const pipelineRetry = 'pipelineRetry';
const errorTexts = {
  [LOAD_FAILURE]: __('We are currently unable to fetch data for the pipeline header.'),
  [POST_FAILURE]: __('An error occurred while making the request.'),
  [DELETE_FAILURE]: __('An error occurred while deleting the pipeline.'),
  [DEFAULT]: __('An unknown error occurred.'),
};

export default {
  name: 'PipelineHeader',
  components: {
    CiIcon,
    ClipboardButton,
    GlAlert,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    PageHeading,
    HeaderActions,
    HeaderBadges,
    TimeAgoTooltip,
    DuoWorkflowAction,
    PipelineAccountVerificationAlert: () =>
      import('ee_component/vue_shared/components/pipeline_account_verification_alert.vue'),
    HeaderMergeTrainsLink: () =>
      import('ee_component/ci/pipeline_details/header/components/header_merge_trains_link.vue'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
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
      result({ data }) {
        // we use a manual subscribeToMore call due to issues with
        // the skip hook not working correctly for the subscription
        if (data?.project?.pipeline?.id && !this.isSubscribed) {
          this.isSubscribed = true;

          this.$apollo.queries.pipeline.subscribeToMore({
            document: pipelineHeaderStatusUpdatedSubscription,
            variables: {
              pipelineId: data.project.pipeline.id,
            },
            updateQuery(
              previousData,
              {
                subscriptionData: {
                  data: { ciPipelineStatusUpdated },
                },
              },
            ) {
              if (ciPipelineStatusUpdated) {
                return {
                  project: {
                    ...previousData.project,
                    pipeline: {
                      ...previousData.project.pipeline,
                      ...ciPipelineStatusUpdated,
                    },
                  },
                };
              }

              return previousData;
            },
          });
        }
      },
      error(error) {
        this.reportFailure(LOAD_FAILURE);
        reportToSentry(this.$options.name, error);
      },
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
      isSubscribed: false,
    };
  },
  computed: {
    loading() {
      return this.$apollo.queries.pipeline.loading;
    },
    hasError() {
      return this.failureType;
    },
    detailedStatus() {
      return this.pipeline?.detailedStatus || {};
    },
    status() {
      return this.pipeline?.status;
    },
    isFinished() {
      return finishedStatuses.includes(this.status);
    },
    failure() {
      switch (this.failureType) {
        case LOAD_FAILURE:
          return {
            text: errorTexts[LOAD_FAILURE],
            variant: 'danger',
          };
        case POST_FAILURE:
          return {
            text: errorTexts[POST_FAILURE],
            variant: 'danger',
          };
        case DELETE_FAILURE:
          return {
            text: errorTexts[DELETE_FAILURE],
            variant: 'danger',
          };
        default:
          return {
            text: errorTexts[DEFAULT],
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
    isFailed() {
      return this.status === 'FAILED';
    },
    pipelinePath() {
      return this.pipeline?.detailedStatus?.detailsPath
        ? `${gon.gitlab_url}${this.pipeline.detailedStatus.detailsPath}`
        : null;
    },
    sourceBranch() {
      return this.pipeline.mergeRequest?.sourceBranch || this.pipeline.ref || null;
    },
    showFixPipelineButton() {
      return this.isFailed && this.pipelinePath && this.sourceBranch;
    },
    getAdditionalContext() {
      return [
        {
          Category: 'pipeline',
          Content: JSON.stringify({
            source_branch: this.sourceBranch,
          }),
        },
        {
          Category: 'merge_request',
          Content: JSON.stringify({
            url: this.paths.mergeRequestPath,
          }),
        },
      ];
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
        }
      } catch (error) {
        this.isRetrying = false;

        this.reportFailure(POST_FAILURE);
        reportToSentry(this.$options.name, error);
      }
    },
    cancelPipeline(id) {
      this.isCanceling = true;
      this.postPipelineAction(pipelineCancel, cancelPipelineMutation, id);
    },
    retryPipeline(id) {
      this.isRetrying = true;
      this.postPipelineAction(pipelineRetry, retryPipelineMutation, id);
    },
    async deletePipeline(id) {
      this.isDeleting = true;

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
        this.isDeleting = false;

        this.reportFailure(DELETE_FAILURE);
        reportToSentry(this.$options.name, error);
      }
    },
  },
  FIX_PIPELINE_AGENT_PRIVILEGES,
};
</script>

<template>
  <div data-testid="pipeline-header">
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

    <gl-loading-icon v-if="loading" class="gl-mt-5 gl-text-center" size="md" />

    <page-heading v-else inline-actions class="gl-mb-0">
      <template #heading>
        <span v-if="pipelineName" data-testid="pipeline-name">
          {{ pipelineName }}
        </span>
        <span v-else data-testid="pipeline-commit-title">
          {{ commitTitle }}
        </span>
      </template>

      <template #description>
        <ci-icon :status="detailedStatus" show-status-text class="gl-mb-3" />
        <div class="gl-inline-block">
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
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
          <clipboard-button
            :text="commitSha"
            category="tertiary"
            :title="__('Copy commit SHA')"
            data-testid="commit-copy-sha"
            size="small"
          />
        </div>
        <div class="gl-inline-block">
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

        <div
          v-safe-html="refText"
          class="gl-my-3 @sm/panel:gl-mt-0"
          data-testid="pipeline-ref-text"
        ></div>
        <div>
          <header-badges :pipeline="pipeline" />

          <div class="gl-inline-block">
            <button
              v-gl-tooltip
              :title="s__('Pipelines|Total number of jobs for the pipeline')"
              class="gl-ml-2 !gl-cursor-default gl-rounded-base gl-border-none gl-bg-transparent gl-p-0"
            >
              <span data-testid="total-jobs">
                <gl-icon name="pipeline" />
                {{ totalJobsText }}
              </span>
            </button>
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
      </template>

      <template #actions>
        <duo-workflow-action
          v-if="showFixPipelineButton"
          class="gl-self-start"
          :project-path="paths.fullProject"
          workflow-definition="fix_pipeline/v1"
          :goal="pipelinePath"
          size="medium"
          :source-branch="sourceBranch"
          :agent-privileges="$options.FIX_PIPELINE_AGENT_PRIVILEGES"
          :additional-context="getAdditionalContext"
        >
          {{ __('Fix pipeline with Duo') }}
        </duo-workflow-action>
        <header-actions
          class="gl-self-start"
          :pipeline="pipeline"
          :is-retrying="isRetrying"
          :is-canceling="isCanceling"
          :is-deleting="isDeleting"
          @retryPipeline="retryPipeline($event)"
          @cancelPipeline="cancelPipeline($event)"
          @deletePipeline="deletePipeline($event)"
        />
      </template>
    </page-heading>

    <pipeline-account-verification-alert class="gl-mt-4" />
  </div>
</template>
