import Vue from 'vue';
import Panel from './panel.vue';

export default () => {
  const element = document.querySelector('#js-google-cloud-databases');
  const attrs = JSON.parse(element.getAttribute('data'));
  return new Vue({
    el: element,
    name: 'GoogleCloudDatabasesPanelRoot',
    render: (createElement) => createElement(Panel, { attrs }),
  });
};
