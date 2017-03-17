import Vue from 'vue';
import PipelinesStore from './stores/pipelines_store';
import PipelinesComponent from './pipelines';
import '../vue_shared/vue_resource_interceptor';

$(() => new Vue({
  el: document.querySelector('.vue-pipelines-index'),

  data() {
    const project = document.querySelector('.pipelines');
    const store = new PipelinesStore();

    return {
      store,
      endpoint: project.dataset.url,
    };
  },
  components: {
    'vue-pipelines': PipelinesComponent,
  },
  template: `
    <vue-pipelines
      :endpoint="endpoint"
      :store="store" />
  `,
}));
