import Vue from 'vue';
import EnvironmentsComponent from './components/environment.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#environments-list-view',
  components: {
    'environments-table-app': EnvironmentsComponent,
  },
  render: createElement => createElement('environments-table-app'),
}));
