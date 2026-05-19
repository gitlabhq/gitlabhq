import Vue from 'vue';
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

  return new Vue({
    el: formContainerEl,
    name: 'ErrorTrackingSettingsRoot',
    pinia,
    render(createElement) {
      return createElement(ErrorTrackingSettings, {
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
    },
  });
};
