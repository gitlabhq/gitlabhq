import Vue from 'vue';
import Panel from './panel.vue';

export default (containerId = '#js-google-cloud-deployments') => {
  const element = document.querySelector(containerId);
  const { ...attrs } = JSON.parse(element.getAttribute('data'));
  return new Vue({
    el: element,
    render: (createElement) => createElement(Panel, { attrs }),
  });
};
