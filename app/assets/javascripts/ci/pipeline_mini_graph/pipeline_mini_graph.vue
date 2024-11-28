<script>
import { GlIcon, GlLoadingIcon, GlTooltipDirective } from '@gitlab/ui';
import Visibility from 'visibilityjs';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { reportToSentry } from '~/ci/utils';
import { getIncreasedPollInterval } from '~/ci/utils/polling_utils';
import { NETWORK_STATUS_READY, PIPELINE_POLL_INTERVAL_DEFAULT } from '~/ci/constants';
import { keepLatestDownstreamPipelines } from '~/ci/pipeline_details/utils/parsing_utils';
import { getQueryHeaders } from '~/ci/pipeline_details/graph/utils';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import getPipelineMiniGraphQuery from './graphql/queries/get_pipeline_mini_graph.query.graphql';
import DownstreamPipelines from './downstream_pipelines.vue';
import PipelineStages from './pipeline_stages.vue';
/**
 * Renders the GraphQL instance of the pipeline mini graph.
 */
export default {
  name: 'PipelineMiniGraph',
  i18n: {
    pipelineMiniGraphFetchError: __('There was a problem fetching the pipeline mini graph.'),
  },
  arrowStyles: ['arrow-icon gl-inline-block gl-mx-1 gl-text-subtle !gl-align-middle'],
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    CiIcon,
    DownstreamPipelines,
    GlIcon,
    GlLoadingIcon,
    PipelineStages,
  },
  props: {
    pipelineEtag: {
      type: String,
      required: true,
    },
    fullPath: {
      type: String,
      required: true,
    },
    iid: {
      type: String,
      required: true,
    },
    isMergeTrain: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['miniGraphStageClick'],
  data() {
    return {
      pollInterval: PIPELINE_POLL_INTERVAL_DEFAULT,
      pipeline: {},
    };
  },
  apollo: {
    pipeline: {
      context() {
        return getQueryHeaders(this.pipelineEtag);
      },
      query: getPipelineMiniGraphQuery,
      notifyOnNetworkStatusChange: true,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      pollInterval() {
        return this.pollInterval;
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
        createAlert({ message: this.$options.i18n.pipelineMiniGraphFetchError });
        reportToSentry(this.$options.name, error);
        this.pollInterval = 0;
      },
    },
  },
  computed: {
    downstreamPipelines() {
      return keepLatestDownstreamPipelines(this.pipeline?.downstream?.nodes);
    },
    hasDownstreamPipelines() {
      return Boolean(this.downstreamPipelines.length);
    },
    pipelinePath() {
      return this.pipeline?.path || '';
    },
    pipelineStages() {
      return this.pipeline?.stages?.nodes || [];
    },
    upstreamPipeline() {
      return this.pipeline?.upstream;
    },
    upstreamTooltipText() {
      return `${this.upstreamPipeline.project.name} - ${this.upstreamPipeline.detailedStatus.label}`;
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
  <div>
    <gl-loading-icon v-if="$apollo.queries.pipeline.loading" />
    <div v-else data-testid="pipeline-mini-graph">
      <ci-icon
        v-if="upstreamPipeline"
        v-gl-tooltip.hover
        :title="upstreamTooltipText"
        :aria-label="upstreamTooltipText"
        :status="upstreamPipeline.detailedStatus"
        :show-tooltip="false"
        class="gl-align-middle"
        data-testid="pipeline-mini-graph-upstream"
      />
      <gl-icon
        v-if="upstreamPipeline"
        :class="$options.arrowStyles"
        name="arrow-right"
        data-testid="upstream-arrow-icon"
        variant="subtle"
      />
      <pipeline-stages
        :is-merge-train="isMergeTrain"
        :stages="pipelineStages"
        @jobActionExecuted="onJobActionExecuted"
        @miniGraphStageClick="$emit('miniGraphStageClick')"
      />
      <gl-icon
        v-if="hasDownstreamPipelines"
        :class="$options.arrowStyles"
        name="arrow-right"
        data-testid="downstream-arrow-icon"
        variant="subtle"
      />
      <downstream-pipelines
        v-if="hasDownstreamPipelines"
        :pipelines="downstreamPipelines"
        :pipeline-path="pipelinePath"
        data-testid="pipeline-mini-graph-downstream"
      />
    </div>
  </div>
</template>
