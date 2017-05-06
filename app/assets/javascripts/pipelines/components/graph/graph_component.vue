<script>
  /* global Flash */
  import Visibility from 'visibilityjs';
  import Poll from '../../../lib/utils/poll';
  import PipelineService from '../../services/pipeline_service';
  import PipelineStore from '../../stores/pipeline_store';
  import stageColumnComponent from './stage_column_component.vue';
  import '../../../flash';

  export default {
    components: {
      stageColumnComponent,
    },

    data() {
      const DOMdata = document.getElementById('js-pipeline-graph-vue').dataset;
      const store = new PipelineStore();

      return {
        isLoading: false,
        endpoint: DOMdata.endpoint,
        store,
        state: store.state,
      };
    },

    created() {
      this.service = new PipelineService(this.endpoint);

      const poll = new Poll({
        resource: this.service,
        method: 'getPipeline',
        successCallback: this.successCallback,
        errorCallback: this.errorCallback,
      });

      if (!Visibility.hidden()) {
        this.isLoading = true;
        poll.makeRequest();
      }

      Visibility.change(() => {
        if (!Visibility.hidden()) {
          poll.restart();
        } else {
          poll.stop();
        }
      });
    },

    methods: {
      successCallback(response) {
        const data = response.json();

        this.isLoading = false;
        this.store.storeGraph(data.details.stages);
      },

      errorCallback() {
        this.isLoading = false;
        return new Flash('An error occurred while fetching the pipeline.');
      },

      capitalizeStageName(name) {
        return name.charAt(0).toUpperCase() + name.slice(1);
      },
    },
  };
</script>
<template>
  <div class="build-content middle-block js-pipeline-graph">
    <div class="pipeline-visualization pipeline-graph">
      <div class="text-center">
        <i
          v-if="isLoading"
          class="loading-icon fa fa-spin fa-spinner fa-3x"
          aria-label="Loading"
          aria-hidden="true" />
      </div>

      <ul
        v-if="!isLoading"
        class="stage-column-list">
        <stage-column-component
          v-for="stage in state.graph"
          :title="capitalizeStageName(stage.name)"
          :jobs="stage.groups"
          :key="stage.name"/>
      </ul>
    </div>
  </div>
</template>
