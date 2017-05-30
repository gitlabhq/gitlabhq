import Vue from 'vue';
import VueResource from 'vue-resource';
import Monitoring from './components/monitoring.vue';

Vue.use(VueResource);

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '.prometheus-graphs',
  components: {
    'monitoring-dashboard': Monitoring,
  },
  render: createElement => createElement('monitoring-dashboard'),
}));
