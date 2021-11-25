import Vue from 'vue';
import { __ } from '~/locale';
import App from './components/screens/app.vue';
import ServiceAccountsForm from './components/screens/service_accounts_form.vue';
import ErrorNoGcpProjects from './components/errors/no_gcp_projects.vue';
import ErrorGcpError from './components/errors/gcp_error.vue';

const elementRenderer = (element, props = {}) => (createElement) =>
  createElement(element, { props });

const rootComponentMap = [
  {
    root: '#js-google-cloud-error-no-gcp-projects',
    component: ErrorNoGcpProjects,
  },
  {
    root: '#js-google-cloud-error-gcp-error',
    component: ErrorGcpError,
  },
  {
    root: '#js-google-cloud-service-accounts',
    component: ServiceAccountsForm,
  },
  {
    root: '#js-google-cloud',
    component: App,
  },
];

export default () => {
  for (let i = 0; i < rootComponentMap.length; i += 1) {
    const { root, component } = rootComponentMap[i];
    const element = document.querySelector(root);
    if (element) {
      const props = JSON.parse(element.getAttribute('data'));
      return new Vue({ el: root, render: elementRenderer(component, props) });
    }
  }
  throw new Error(__('Unknown root'));
};
