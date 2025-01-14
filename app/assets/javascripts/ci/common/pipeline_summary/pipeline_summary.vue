<script>
import { GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Visibility from 'visibilityjs';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import { getIncreasedPollInterval } from '~/ci/utils/polling_utils';
import { NETWORK_STATUS_READY, PIPELINE_POLL_INTERVAL_DEFAULT } from '~/ci/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import getPipelineSummaryQuery from './graphql/queries/get_pipeline_summary.query.graphql';

export default {
  name: 'PipelineSummary',
  i18n: {
    loadingText: s__('Pipeline|Checking pipeline status'),
    pipelineSummaryFetchError: __('There was a problem fetching the pipeline summary.'),
    pipelineStatusText: s__('Pipelines|Pipeline %{linkStart}#%{pipelineId}%{linkEnd} %{status}'),
    pipelineCommitText: s__('Pipelines|Pipeline %{status} for %{linkStart}%{commit}%{linkEnd} '),
  },
  components: {
    CiIcon,
    GlLink,
    GlLoadingIcon,
    GlSprintf,
    PipelineMiniGraph,
    TimeAgoTooltip,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    includeCommitInfo: {
      type: Boolean,
      required: false,
      default: false,
    },
    pipelineEtag: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      pipeline: {},
      pollInterval: PIPELINE_POLL_INTERVAL_DEFAULT,
    };
  },
  apollo: {
    pipeline: {
      context() {
        return getQueryHeaders(this.pipelineEtag);
      },
      query: getPipelineSummaryQuery,
      notifyOnNetworkStatusChange: true,
      pollInterval() {
        return this.pollInterval;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
          includeCommitInfo: this.includeCommitInfo,
        };
      },
      result({ networkStatus }) {
        // We need this for handling the reactive poll interval while also using frontend cache
        // a status of 7 = 'ready'
        if (networkStatus !== NETWORK_STATUS_READY) return;
        this.pollInterval = this.increasePollInterval();
      },
      update({ project }) {
        return project?.pipeline || {};
      },
      error(error) {
        createAlert({ message: this.$options.i18n.pipelineSummaryFetchError });
        reportToSentry(this.$options.name, error);
      },
    },
  },
  computed: {
    commitPath() {
      return this.pipeline?.commit?.webPath;
    },
    commitSha() {
      return this.pipeline?.commit?.shortId;
    },
    downstreamPipelines() {
      return this.pipeline?.downstream?.nodes || [];
    },
    finishedAt() {
      return this.pipeline?.finishedAt;
    },
    isLoading() {
      return this.$apollo.queries.pipeline.loading;
    },
    pipelineId() {
      return getIdFromGraphQLId(this.pipeline?.id);
    },
    pipelinePath() {
      return this.status?.detailsPath || '';
    },
    pipelineStages() {
      return this.pipeline?.stages?.nodes || [];
    },
    status() {
      return this.pipeline?.detailedStatus || null;
    },
    statusLabel() {
      return this.status?.label || '';
    },
    upstreamPipeline() {
      return this.pipeline?.upstream || {};
    },
  },
  mounted() {
    Visibility.change(() => {
      this.handlePolling();
    });
  },
  methods: {
    /** Note: cannot use `toggleQueryPollingByVisibility` because interval is dynamic */
    handlePolling() {
      if (!Visibility.hidden()) {
        this.resetPollInterval();
      } else {
        this.pollInterval = 0;
      }
    },
    increasePollInterval() {
      return getIncreasedPollInterval(this.pollInterval);
    },
    onJobActionExecuted() {
      this.resetPollInterval();
    },
    resetPollInterval() {
      this.pollInterval = PIPELINE_POLL_INTERVAL_DEFAULT;
    },
  },
};
</script>

<template>
  <div class="w-100">
    <div v-if="isLoading" class="align-items-center gl-mx-2 gl-flex">
      <gl-loading-icon class="gl-mr-4" />
      {{ $options.i18n.loadingText }}
    </div>
    <div v-else class="align-items-center w-100 gl-flex">
      <div
        class="flex-grow-1 justify-space-between gl-flex gl-flex-wrap gl-gap-3"
        :class="{ 'align-items-center': !finishedAt }"
      >
        <ci-icon v-if="status" class="gl-mt-1 gl-self-start" :status="status" />
        <div class="flex-grow-1 gl-flex gl-flex-col">
          <span>
            <gl-sprintf :message="$options.i18n.pipelineStatusText">
              <template #status>{{ statusLabel }}</template>
              <template #link="{ content }">
                <gl-link data-testid="pipeline-path" :href="pipelinePath">
                  <gl-sprintf :message="content">
                    <template #pipelineId>{{ pipelineId }}</template>
                  </gl-sprintf>
                </gl-link>
              </template>
            </gl-sprintf>
          </span>
          <span class="align-items-center gl-flex gl-text-sm gl-text-subtle">
            <span v-if="includeCommitInfo" data-testid="commit-info">
              <gl-sprintf :message="$options.i18n.pipelineCommitText">
                <template #status>{{ statusLabel }}</template>
                <template #link>
                  <gl-link
                    data-testid="commit-path"
                    :href="commitPath"
                    class="commit-sha-container gl-mr-2"
                  >
                    {{ commitSha }}
                  </gl-link>
                </template>
              </gl-sprintf>
            </span>
            <time-ago-tooltip v-if="finishedAt" :time="finishedAt" tooltip-placement="bottom" />
          </span>
        </div>
        <pipeline-mini-graph
          data-testid="pipeline-summary-pipeline-mini-graph"
          :downstream-pipelines="downstreamPipelines"
          :pipeline-path="pipelinePath"
          :pipeline-stages="pipelineStages"
          :upstream-pipeline="upstreamPipeline"
          @jobActionExecuted="onJobActionExecuted"
        />
      </div>
    </div>
  </div>
</template>
