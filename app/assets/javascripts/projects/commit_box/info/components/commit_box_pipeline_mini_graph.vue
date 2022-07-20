<script>
import { GlLoadingIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { __ } from '~/locale';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import {
  getQueryHeaders,
  toggleQueryPollingByVisibility,
} from '~/pipelines/components/graph/utils';
import { formatStages } from '../utils';
import getLinkedPipelinesQuery from '../graphql/queries/get_linked_pipelines.query.graphql';
import getPipelineStagesQuery from '../graphql/queries/get_pipeline_stages.query.graphql';
import { COMMIT_BOX_POLL_INTERVAL } from '../constants';

export default {
  i18n: {
    linkedPipelinesFetchError: __('There was a problem fetching linked pipelines.'),
    stageConversionError: __('There was a problem handling the pipeline data.'),
    stagesFetchError: __('There was a problem fetching the pipeline stages.'),
  },
  components: {
    GlLoadingIcon,
    PipelineMiniGraph,
    LinkedPipelinesMiniList: () =>
      import('ee_component/vue_shared/components/linked_pipelines_mini_list.vue'),
  },
  inject: {
    fullPath: {
      default: '',
    },
    iid: {
      default: '',
    },
    graphqlResourceEtag: {
      default: '',
    },
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
  },
  apollo: {
    pipeline: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getLinkedPipelinesQuery,
      pollInterval: COMMIT_BOX_POLL_INTERVAL,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      skip() {
        return !this.fullPath || !this.iid;
      },
      update({ project }) {
        return project?.pipeline;
      },
      error() {
        createFlash({ message: this.$options.i18n.linkedPipelinesFetchError });
      },
    },
    pipelineStages: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getPipelineStagesQuery,
      pollInterval: COMMIT_BOX_POLL_INTERVAL,
      variables() {
        return {
          fullPath: this.fullPath,
          iid: this.iid,
        };
      },
      update({ project }) {
        return project?.pipeline?.stages?.nodes || [];
      },
      error() {
        createFlash({ message: this.$options.i18n.stagesFetchError });
      },
    },
  },
  data() {
    return {
      formattedStages: [],
      pipeline: null,
      pipelineStages: [],
    };
  },
  computed: {
    hasDownstream() {
      return this.pipeline?.downstream?.nodes.length > 0;
    },
    downstreamPipelines() {
      return this.pipeline?.downstream?.nodes;
    },
    upstreamPipeline() {
      return this.pipeline?.upstream;
    },
  },
  watch: {
    pipelineStages() {
      // pipelineStages are from GraphQL
      // stages are from REST
      // we do this to use dropdown_path for fetching jobs on stage click
      try {
        this.formattedStages = formatStages(this.pipelineStages, this.stages);
      } catch (error) {
        createFlash({
          message: this.$options.i18n.stageConversionError,
          captureError: true,
          error,
        });
      }
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.pipelineStages);
    toggleQueryPollingByVisibility(this.$apollo.queries.pipeline);
  },
};
</script>

<template>
  <div class="gl-pt-2">
    <gl-loading-icon v-if="$apollo.queries.pipeline.loading" />
    <div v-else class="gl-align-items-center gl-display-flex">
      <linked-pipelines-mini-list
        v-if="upstreamPipeline"
        :triggered-by="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
          upstreamPipeline,
        ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
        data-testid="commit-box-mini-graph-upstream"
      />

      <pipeline-mini-graph :stages="formattedStages" data-testid="commit-box-mini-graph" />

      <linked-pipelines-mini-list
        v-if="hasDownstream"
        :triggered="downstreamPipelines"
        :pipeline-path="pipeline.path"
        data-testid="commit-box-mini-graph-downstream"
      />
    </div>
  </div>
</template>
