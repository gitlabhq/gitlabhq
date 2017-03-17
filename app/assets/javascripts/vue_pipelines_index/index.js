import PipelinesStore from './stores/pipelines_store';
import PipelinesComponent from './pipelines';
import '../vue_shared/vue_resource_interceptor';

const Vue = window.Vue = require('vue');
window.Vue.use(require('vue-resource'));

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
