import Vue from 'vue';
import Form from './form.vue';

export default (containerId = '#js-google-cloud-gcp-regions') => {
  const element = document.querySelector(containerId);
  const { ...attrs } = JSON.parse(element.getAttribute('data'));
  return new Vue({
    el: element,
    render: (createElement) => createElement(Form, { attrs }),
  });
};
