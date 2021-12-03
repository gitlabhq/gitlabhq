import Vue from 'vue';
import App from './components/app.vue';

export default () => {
  const root = '#js-google-cloud';
  const element = document.querySelector(root);
  const { screen, ...attrs } = JSON.parse(element.getAttribute('data'));
  return new Vue({
    el: element,
    render: (createElement) => createElement(App, { props: { screen }, attrs }),
  });
};
