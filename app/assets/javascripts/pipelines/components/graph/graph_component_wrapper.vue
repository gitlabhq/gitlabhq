<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import { DEFAULT, LOAD_FAILURE } from '../../constants';
import getPipelineDetails from '../../graphql/queries/get_pipeline_details.query.graphql';
import PipelineGraph from './graph_component.vue';
import { unwrapPipelineData } from './utils';

export default {
  name: 'PipelineGraphWrapper',
  components: {
    GlAlert,
    GlLoadingIcon,
    PipelineGraph,
  },
  inject: {
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
    [LOAD_FAILURE]: __('We are currently unable to fetch data for this pipeline.'),
    [DEFAULT]: __('An unknown error occurred while loading this graph.'),
  },
  apollo: {
    pipeline: {
      query: getPipelineDetails,
      variables() {
        return {
          projectPath: this.pipelineProjectPath,
          iid: this.pipelineIid,
        };
      },
      update(data) {
        return unwrapPipelineData(this.pipelineIid, data);
      },
      error() {
        this.reportFailure(LOAD_FAILURE);
      },
    },
  },
  computed: {
    alert() {
      switch (this.alertType) {
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
  },
  methods: {
    hideAlert() {
      this.showAlert = false;
    },
    reportFailure(type) {
      this.showAlert = true;
      this.failureType = type;
    },
  },
};
</script>
<template>
  <gl-alert v-if="showAlert" :variant="alert.variant" @dismiss="hideAlert">
    {{ alert.text }}
  </gl-alert>
  <gl-loading-icon
    v-else-if="$apollo.queries.pipeline.loading"
    class="gl-mx-auto gl-my-4"
    size="lg"
  />
  <pipeline-graph v-else :pipeline="pipeline" />
</template>
