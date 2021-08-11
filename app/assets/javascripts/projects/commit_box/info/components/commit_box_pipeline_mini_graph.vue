<script>
import { GlLoadingIcon } from '@gitlab/ui';
import createFlash from '~/flash';
import { __ } from '~/locale';
import PipelineMiniGraph from '~/pipelines/components/pipelines_list/pipeline_mini_graph.vue';
import getLinkedPipelinesQuery from '../graphql/queries/get_linked_pipelines.query.graphql';

export default {
  i18n: {
    linkedPipelinesFetchError: __('There was a problem fetching linked pipelines.'),
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
  },
  props: {
    stages: {
      type: Array,
      required: true,
    },
  },
  apollo: {
    pipeline: {
      query: getLinkedPipelinesQuery,
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
  },
  data() {
    return {
      pipeline: null,
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
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="$apollo.queries.pipeline.loading" />
    <div v-else>
      <linked-pipelines-mini-list
        v-if="upstreamPipeline"
        :triggered-by="[upstreamPipeline]"
        data-testid="commit-box-mini-graph-upstream"
      />

      <pipeline-mini-graph
        :stages="stages"
        class="gl-display-inline"
        data-testid="commit-box-mini-graph"
      />

      <linked-pipelines-mini-list
        v-if="hasDownstream"
        :triggered="downstreamPipelines"
        data-testid="commit-box-mini-graph-downstream"
      />
    </div>
  </div>
</template>
