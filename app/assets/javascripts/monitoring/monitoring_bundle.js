import Vue from 'vue';
import Dashboard from './components/dashboard.vue';

export default () => new Vue({
  el: '#prometheus-graphs',
  render: createElement => createElement(Dashboard),
});
