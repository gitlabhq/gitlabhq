import Vue from 'vue';
import Form from './form.vue';

export default (containerId = '#js-google-cloud-service-accounts') => {
  const element = document.querySelector(containerId);
  const { ...attrs } = JSON.parse(element.getAttribute('data'));
  return new Vue({
    el: element,
    render: (createElement) => createElement(Form, { attrs }),
  });
};
