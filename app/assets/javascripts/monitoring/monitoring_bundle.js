import Vue from 'vue';
import Dashboard from './components/dashboard.vue';

export default () => {
  new Vue({ // eslint-disable-line no-new
    el: '#prometheus-graphs',
    render: createElement => createElement(Dashboard),
  });
};
