<script>
import { GlBadge, GlIcon, GlLink, GlLoadingIcon, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import CiBadgeLink from '~/vue_shared/components/ci_badge_link.vue';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { LOAD_FAILURE, POST_FAILURE, DELETE_FAILURE, DEFAULT } from '../constants';
import getPipelineQuery from '../graphql/queries/get_pipeline_header_data.query.graphql';
import TimeAgo from './pipelines_list/time_ago.vue';
import { getQueryHeaders } from './graph/utils';

const POLL_INTERVAL = 10000;

export default {
  name: 'PipelineDetailsHeader',
  finishedStatuses: ['FAILED', 'SUCCESS', 'CANCELED'],
  components: {
    CiBadgeLink,
    ClipboardButton,
    GlBadge,
    GlIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    TimeAgo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  i18n: {
    scheduleBadgeText: s__('Pipelines|Scheduled'),
    scheduleBadgeTooltip: __('This pipeline was triggered by a schedule'),
    childBadgeText: s__('Pipelines|Child pipeline (%{linkStart}parent%{linkEnd})'),
    childBadgeTooltip: __('This is a child pipeline within the parent pipeline'),
    latestBadgeText: s__('Pipelines|latest'),
    latestBadgeTooltip: __('Latest pipeline for the most recent commit on this branch'),
    mergeTrainBadgeText: s__('Pipelines|merge train'),
    mergeTrainBadgeTooltip: s__(
      'Pipelines|This pipeline ran on the contents of this merge request combined with the contents of all other merge requests queued for merging into the target branch.',
    ),
    invalidBadgeText: s__('Pipelines|yaml invalid'),
    failedBadgeText: s__('Pipelines|error'),
    autoDevopsBadgeText: s__('Pipelines|Auto DevOps'),
    autoDevopsBadgeTooltip: __(
      'This pipeline makes use of a predefined CI/CD configuration enabled by Auto DevOps.',
    ),
    detachedBadgeText: s__('Pipelines|merge request'),
    detachedBadgeTooltip: s__(
      "Pipelines|This pipeline ran on the contents of this merge request's source branch, not the target branch.",
    ),
    stuckBadgeText: s__('Pipelines|stuck'),
    stuckBadgeTooltip: s__('Pipelines|This pipeline is stuck'),
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
  props: {
    name: {
      type: String,
      required: false,
      default: '',
    },
    totalJobs: {
      type: String,
      required: false,
      default: '',
    },
    computeCredits: {
      type: String,
      required: false,
      default: '',
    },
    yamlErrors: {
      type: String,
      required: false,
      default: '',
    },
    failureReason: {
      type: String,
      required: false,
      default: '',
    },
    refText: {
      type: String,
      required: false,
      default: '',
    },
    badges: {
      type: Object,
      required: false,
      default: () => {},
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
    usersName() {
      return this.pipeline?.user?.name || '';
    },
    userPath() {
      return this.pipeline?.user?.webPath || '';
    },
    shortId() {
      return this.pipeline?.commit?.shortId || '';
    },
    commitPath() {
      return this.pipeline?.commit?.webPath || '';
    },
    totalJobsText() {
      return sprintf(__('%{jobs} Jobs'), {
        jobs: this.totalJobs,
      });
    },
    triggeredText() {
      return sprintf(__('%{linkStart}%{name}%{linkEnd} triggered pipeline for commit'), {
        name: this.usersName,
      });
    },
    inProgress() {
      return this.status === 'RUNNING';
    },
    inProgressText() {
      return sprintf(__('In progress, queued for %{queuedDuration} seconds'), {
        queuedDuration: this.pipeline?.queuedDuration || 0,
      });
    },
  },
  methods: {
    reportFailure(errorType, errorMessages = []) {
      this.failureType = errorType;
      this.failureMessages = errorMessages;
    },
  },
};
</script>

<template>
  <div class="gl-mt-3">
    <gl-loading-icon v-if="loading" class="gl-text-left" size="lg" />
    <template v-else>
      <h3 v-if="name" class="gl-mt-0 gl-mb-2" data-testid="pipeline-name">{{ name }}</h3>
      <div>
        <ci-badge-link :status="detailedStatus" />
        <div class="gl-ml-2 gl-mb-2 gl-display-inline-block gl-h-6">
          <gl-sprintf :message="triggeredText">
            <template #link="{ content }">
              <gl-link
                :href="userPath"
                class="gl-text-gray-900 gl-font-weight-bold"
                target="_blank"
              >
                {{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
          <gl-link
            :href="commitPath"
            class="gl-bg-blue-50 gl-rounded-base gl-px-2 gl-mx-2"
            data-testid="commit-link"
          >
            {{ shortId }}
          </gl-link>
          <clipboard-button
            :text="shortId"
            category="tertiary"
            :title="__('Copy commit SHA')"
            size="small"
          />
          <time-ago
            v-if="isFinished"
            :pipeline="pipeline"
            class="gl-display-inline gl-mb-0"
            :display-calendar-icon="false"
            font-size="gl-font-md"
          />
        </div>
      </div>
      <div v-safe-html="refText" class="gl-mb-2" data-testid="pipeline-ref-text"></div>
      <div>
        <gl-badge
          v-if="badges.schedule"
          v-gl-tooltip
          :title="$options.i18n.scheduleBadgeTooltip"
          variant="info"
        >
          {{ $options.i18n.scheduleBadgeText }}
        </gl-badge>
        <gl-badge
          v-if="badges.child"
          v-gl-tooltip
          :title="$options.i18n.childBadgeTooltip"
          variant="info"
        >
          <gl-sprintf :message="$options.i18n.childBadgeText">
            <template #link="{ content }">
              <gl-link :href="paths.triggeredByPath" target="_blank">
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
        >
          {{ $options.i18n.latestBadgeText }}
        </gl-badge>
        <gl-badge
          v-if="badges.mergeTrainPipeline"
          v-gl-tooltip
          :title="$options.i18n.mergeTrainBadgeTooltip"
          variant="info"
        >
          {{ $options.i18n.mergeTrainBadgeText }}
        </gl-badge>
        <gl-badge v-if="badges.invalid" v-gl-tooltip :title="yamlErrors" variant="danger">
          {{ $options.i18n.invalidBadgeText }}
        </gl-badge>
        <gl-badge v-if="badges.failed" v-gl-tooltip :title="failureReason" variant="danger">
          {{ $options.i18n.failedBadgeText }}
        </gl-badge>
        <gl-badge
          v-if="badges.autoDevops"
          v-gl-tooltip
          :title="$options.i18n.autoDevopsBadgeTooltip"
          variant="info"
        >
          {{ $options.i18n.autoDevopsBadgeText }}
        </gl-badge>
        <gl-badge
          v-if="badges.detached"
          v-gl-tooltip
          :title="$options.i18n.detachedBadgeTooltip"
          variant="info"
          data-qa-selector="merge_request_badge_tag"
        >
          {{ $options.i18n.detachedBadgeText }}
        </gl-badge>
        <gl-badge
          v-if="badges.stuck"
          v-gl-tooltip
          :title="$options.i18n.stuckBadgeTooltip"
          variant="warning"
        >
          {{ $options.i18n.stuckBadgeText }}
        </gl-badge>
        <span class="gl-ml-2" data-testid="total-jobs">
          <gl-icon name="pipeline" />
          {{ totalJobsText }}
        </span>
        <span v-if="isFinished" class="gl-ml-2" data-testid="compute-credits">
          <gl-icon name="quota" />
          {{ computeCredits }}
        </span>
        <span v-if="inProgress" class="gl-ml-2" data-testid="pipeline-running-text">
          <gl-icon name="timer" />
          {{ inProgressText }}
        </span>
      </div>
    </template>
  </div>
</template>
