import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import Panel from './panel.vue';

export default (containerId = '#js-google-cloud-configuration') => {
  const element = document.querySelector(containerId);
  const {
    configurationUrl,
    deploymentsUrl,
    databasesUrl,
    serviceAccounts,
    createServiceAccountUrl,
    emptyIllustrationUrl,
    configureGcpRegionsUrl,
    gcpRegions,
    revokeOauthUrl,
  } = JSON.parse(element.getAttribute('data'));

  return initVueApp({
    el: element,
    name: 'GoogleCloudConfigurationPanelRoot',
    component: Panel,
    props: {
      configurationUrl,
      deploymentsUrl,
      databasesUrl,
      serviceAccounts,
      createServiceAccountUrl,
      emptyIllustrationUrl,
      configureGcpRegionsUrl,
      gcpRegions,
      revokeOauthUrl,
    },
  });
};
