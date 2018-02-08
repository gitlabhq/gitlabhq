import Vue from 'vue';
import Dashboard from './components/dashboard.vue';

export default () => Vue.create({
  el: '#prometheus-graphs',
  render: createElement => createElement(Dashboard),
});
