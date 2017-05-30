import Vue from 'vue';
import PipelinesMediator from './pipeline_details_mediatior';
import pipelineGraph from './components/graph/graph_component.vue';

document.addEventListener('DOMContentLoaded', () => {
  const dataset = document.querySelector('.js-pipeline-details-vue').dataset;

  const mediator = new PipelinesMediator({ endpoint: dataset.endpoint });

  mediator.fetchPipeline();

  const pipelineGraphApp = new Vue({
    el: '#js-pipeline-graph-vue',
    data() {
      return {
        mediator,
      };
    },
    components: {
      pipelineGraph,
    },
    render(createElement) {
      return createElement('pipeline-graph', {
        props: {
          isLoading: this.mediator.state.isLoading,
          pipeline: this.mediator.store.state.pipeline,
        },
      });
    },
  });

  return pipelineGraphApp;
});
