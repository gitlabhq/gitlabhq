<script>
import { GlLink, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import Visibility from 'visibilityjs';
import { createAlert } from '~/alert';
import { __, s__ } from '~/locale';
import { getIncreasedPollInterval } from '~/ci/utils/polling_utils';
import { NETWORK_STATUS_READY, PIPELINE_POLL_INTERVAL_DEFAULT } from '~/ci/constants';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import PipelineMiniGraph from '~/ci/pipeline_mini_graph/pipeline_mini_graph.vue';
import getPipelineMetadataQuery from './graphql/queries/get_pipeline_metadata.query.graphql';

export default {
  name: 'PipelineSummary',
  i18n: {
    loadingText: s__('Pipeline|Checking pipeline status'),
    pipelineMetadataFetchError: __('There was a problem fetching the pipeline metadata.'),
    pipelineStatusText: s__('Pipelines|Pipeline %{linkStart}#%{pipelineId}%{linkEnd} %{status}'),
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
    pipelineEtag: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      pipelineInfo: {},
      pollInterval: PIPELINE_POLL_INTERVAL_DEFAULT,
    };
  },
  apollo: {
    pipelineInfo: {
      context() {
        return getQueryHeaders(this.pipelineEtag);
      },
      query: getPipelineMetadataQuery,
      notifyOnNetworkStatusChange: true,
      pollInterval() {
        return this.pollInterval;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
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
      error() {
        createAlert({ message: this.$options.i18n.pipelineMetadataFetchError });
      },
    },
  },
  computed: {
    finishedAt() {
      return this.pipelineInfo?.finishedAt;
    },
    isLoading() {
      return this.$apollo.queries.pipelineInfo.loading;
    },
    pipelineId() {
      return getIdFromGraphQLId(this.pipelineInfo?.id);
    },
    pipelinePath() {
      return this.status?.detailsPath || '';
    },
    status() {
      return this.pipelineInfo?.detailedStatus || null;
    },
    statusLabel() {
      return this.status?.label || '';
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
                <gl-link :href="pipelinePath">
                  <gl-sprintf :message="content">
                    <template #pipelineId>{{ pipelineId }}</template>
                  </gl-sprintf>
                </gl-link>
              </template>
            </gl-sprintf>
          </span>
          <time-ago-tooltip
            v-if="finishedAt"
            class="gl-line-height-0 gl-flex gl-text-sm gl-text-subtle"
            :time="finishedAt"
            tooltip-placement="bottom"
          />
        </div>
        <pipeline-mini-graph
          data-testid="pipeline-summary-pipeline-mini-graph"
          :full-path="fullPath"
          :iid="iid"
          :pipeline-etag="pipelineEtag"
          @jobActionExecuted="onJobActionExecuted"
        />
      </div>
    </div>
  </div>
</template>
