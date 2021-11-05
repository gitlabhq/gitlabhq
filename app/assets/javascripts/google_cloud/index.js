import Vue from 'vue';
import App from './components/app.vue';

const elementRenderer = (element, props = {}) => (createElement) =>
  createElement(element, { props });

export default () => {
  const root = document.querySelector('#js-google-cloud');

  // uncomment this once backend is ready
  // const dataset = JSON.parse(root.getAttribute('data'));
  const mockDataset = {
    createServiceAccountUrl: '#create-url',
    serviceAccounts: [],
    emptyIllustrationUrl:
      'https://gitlab.com/gitlab-org/gitlab-svgs/-/raw/main/illustrations/pipelines_empty.svg',
  };
  return new Vue({ el: root, render: elementRenderer(App, mockDataset) });
};
