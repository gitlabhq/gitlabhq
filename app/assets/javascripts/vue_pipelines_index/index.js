import Vue from 'vue';
import PipelinesStore from './stores/pipelines_store';
import PipelinesComponent from './pipelines';
import '../vue_shared/vue_resource_interceptor';

$(() => new Vue({
  el: document.querySelector('#pipelines-list-vue'),

  data() {
    const store = new PipelinesStore();

    return {
      store,
    };
  },
  components: {
    'vue-pipelines': PipelinesComponent,
  },
  template: `
    <vue-pipelines :store="store" />
  `,
}));
