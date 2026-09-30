import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Panel from './panel.vue';

export default (containerId = '#js-google-cloud-deployments') => {
  const element = document.querySelector(containerId);
  const {
    configurationUrl,
    deploymentsUrl,
    databasesUrl,
    enableCloudRunUrl,
    enableCloudStorageUrl,
  } = JSON.parse(element.getAttribute('data'));

  return initVueApp({
    el: element,
    name: 'GoogleCloudDeploymentsPanelRoot',
    component: Panel,
    props: {
      configurationUrl,
      deploymentsUrl,
      databasesUrl,
      enableCloudRunUrl,
      enableCloudStorageUrl,
    },
  });
};
