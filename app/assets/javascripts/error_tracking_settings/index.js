import { initVueApp } from '~/lib/utils/vue3compat/init_vue_app';
import { pinia } from '~/pinia/instance';
import ErrorTrackingSettings from './components/app.vue';

export default () => {
  const formContainerEl = document.querySelector('.js-error-tracking-form');
  const {
    dataset: {
      apiHost,
      enabled,
      integrated,
      project,
      token,
      listProjectsEndpoint,
      operationsSettingsEndpoint,
      gitlabDsn,
    },
  } = formContainerEl;

  return initVueApp({
    el: formContainerEl,
    name: 'ErrorTrackingSettingsRoot',
    pinia,
    component: ErrorTrackingSettings,
    props: {
      initialApiHost: apiHost,
      initialEnabled: enabled,
      initialIntegrated: integrated,
      initialProject: project,
      initialToken: token,
      listProjectsEndpoint,
      operationsSettingsEndpoint,
      gitlabDsn,
    },
  });
};
