import Vue from 'vue';
import App from './components/app.vue';

const elementRenderer = (element, props = {}) => (createElement) =>
  createElement(element, { props });

export default () => {
  const root = document.querySelector('#js-google-cloud');
  const props = JSON.parse(root.getAttribute('data'));
  return new Vue({ el: root, render: elementRenderer(App, props) });
};
