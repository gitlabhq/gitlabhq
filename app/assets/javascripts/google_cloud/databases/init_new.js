import Vue from 'vue';
import Form from './cloudsql/create_instance_form.vue';

export default () => {
  const element = document.querySelector('#js-google-cloud-databases-cloudsql-form');
  const attrs = JSON.parse(element.getAttribute('data'));
  return new Vue({
    el: element,
    render: (createElement) => createElement(Form, { attrs }),
  });
};
