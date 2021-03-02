<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import getPipelineDetails from 'shared_queries/pipelines/get_pipeline_details.query.graphql';
import { __ } from '~/locale';
import { DEFAULT, DRAW_FAILURE, LOAD_FAILURE } from '../../constants';
import PipelineGraph from './graph_component.vue';
import {
  getQueryHeaders,
  reportToSentry,
  toggleQueryPollingByVisibility,
  unwrapPipelineData,
} from './utils';

export default {
  name: 'PipelineGraphWrapper',
  components: {
    GlAlert,
    GlLoadingIcon,
    PipelineGraph,
  },
  inject: {
    graphqlResourceEtag: {
      default: '',
    },
    metricsPath: {
      default: '',
    },
    pipelineIid: {
      default: '',
    },
    pipelineProjectPath: {
      default: '',
    },
  },
  data() {
    return {
      pipeline: null,
      alertType: null,
      showAlert: false,
    };
  },
  errorTexts: {
    [DRAW_FAILURE]: __('An error occurred while drawing job relationship links.'),
    [LOAD_FAILURE]: __('We are currently unable to fetch data for this pipeline.'),
    [DEFAULT]: __('An unknown error occurred while loading this graph.'),
  },
  apollo: {
    pipeline: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getPipelineDetails,
      pollInterval: 10000,
      variables() {
        return {
          projectPath: this.pipelineProjectPath,
          iid: this.pipelineIid,
        };
      },
      update(data) {
        return unwrapPipelineData(this.pipelineProjectPath, data);
      },
      error() {
        this.reportFailure(LOAD_FAILURE);
      },
    },
  },
  computed: {
    alert() {
      switch (this.alertType) {
        case DRAW_FAILURE:
          return {
            text: this.$options.errorTexts[DRAW_FAILURE],
            variant: 'danger',
          };
        case LOAD_FAILURE:
          return {
            text: this.$options.errorTexts[LOAD_FAILURE],
            variant: 'danger',
          };
        default:
          return {
            text: this.$options.errorTexts[DEFAULT],
            variant: 'danger',
          };
      }
    },
    configPaths() {
      return {
        graphqlResourceEtag: this.graphqlResourceEtag,
        metricsPath: this.metricsPath,
      };
    },
    showLoadingIcon() {
      /*
        Shows the icon only when the graph is empty, not when it is is
        being refetched, for instance, on action completion
      */
      return this.$apollo.queries.pipeline.loading && !this.pipeline;
    },
  },
  mounted() {
    toggleQueryPollingByVisibility(this.$apollo.queries.pipeline);
  },
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
  },
  methods: {
    hideAlert() {
      this.showAlert = false;
    },
    refreshPipelineGraph() {
      this.$apollo.queries.pipeline.refetch();
    },
    reportFailure(type) {
      this.showAlert = true;
      this.alertType = type;
      reportToSentry(this.$options.name, this.alertType);
    },
  },
};
</script>
<template>
  <div>
    <gl-alert v-if="showAlert" :variant="alert.variant" @dismiss="hideAlert">
      {{ alert.text }}
    </gl-alert>
    <gl-loading-icon v-if="showLoadingIcon" class="gl-mx-auto gl-my-4" size="lg" />
    <pipeline-graph
      v-if="pipeline"
      :config-paths="configPaths"
      :pipeline="pipeline"
      @error="reportFailure"
      @refreshPipelineGraph="refreshPipelineGraph"
    />
  </div>
</template>
