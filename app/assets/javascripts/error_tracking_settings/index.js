import Vue from 'vue';
import ErrorTrackingSettings from './components/app.vue';
import createStore from './store';

export default () => {
  const formContainerEl = document.querySelector('.js-error-tracking-form');
  const {
    dataset: { apiHost, enabled, project, token, listProjectsEndpoint, operationsSettingsEndpoint },
  } = formContainerEl;

  return new Vue({
    el: formContainerEl,
    store: createStore(),
    render(createElement) {
      return createElement(ErrorTrackingSettings, {
        props: {
          initialApiHost: apiHost,
          initialEnabled: enabled,
          initialProject: project,
          initialToken: token,
          listProjectsEndpoint,
          operationsSettingsEndpoint,
        },
      });
    },
  });
};
