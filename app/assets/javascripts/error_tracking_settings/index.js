import Vue from 'vue';
import ErrorTrackingSettings from './components/app.vue';
import createStore from './store';

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
    store: createStore(),
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
