import Vue from 'vue';
import pipelineGraph from './components/graph/graph_component.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#js-pipeline-graph-vue',
  components: {
    pipelineGraph,
  },
  render: createElement => createElement('pipeline-graph'),
}));
