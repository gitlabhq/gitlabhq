import Vue from 'vue';
import Monitoring from './components/monitoring.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#prometheus-graphs',
  components: {
    'monitoring-dashboard': Monitoring,
  },
  render: createElement => createElement('monitoring-dashboard'),
}));
