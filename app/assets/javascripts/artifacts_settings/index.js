import Vue from 'vue';
import VueApollo from 'vue-apollo';
import KeepLatestArtifactToggle from '~/artifacts_settings/keep_latest_artifact_toggle.vue';
import createDefaultClient from '~/lib/graphql';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export default (containerId = 'js-artifacts-settings-app') => {
  const containerEl = document.getElementById(containerId);

  if (!containerEl) {
    return false;
  }

  const { fullPath, helpPagePath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    provide: {
      fullPath,
      helpPagePath,
    },
    render(createElement) {
      return createElement(KeepLatestArtifactToggle);
    },
  });
};
