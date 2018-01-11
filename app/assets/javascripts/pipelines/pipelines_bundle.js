import Vue from 'vue';
import PipelinesStore from './stores/pipelines_store';
import pipelinesComponent from './components/pipelines.vue';
import Translate from '../vue_shared/translate';

Vue.use(Translate);

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#pipelines-list-vue',
  components: {
    pipelinesComponent,
  },
  data() {
    const store = new PipelinesStore();

    return {
      store,
    };
  },
  render(createElement) {
    return createElement('pipelines-component', {
      props: {
        store: this.store,
      },
    });
  },
}));
