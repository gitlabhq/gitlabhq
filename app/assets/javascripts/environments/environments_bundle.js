import Vue from 'vue';
import EnvironmentsComponent from './components/environment.vue';

$(() => {
  new Vue({ // eslint-disable-line
    el: '#js-environments-list-view',
    components: {
      'environments-component': EnvironmentsComponent,
    },
    render: createElement => createElement('environments-component'),
  });
});
