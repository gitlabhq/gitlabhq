import Vue from 'vue';
import Dashboard from './components/dashboard.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#prometheus-graphs',
  render: createElement => createElement(Dashboard),
}));
