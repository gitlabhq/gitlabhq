import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

Vue.use(VueApollo);

export function initForkApp() {
  const el = document.getElementById('fork-groups-mount-element');

  if (!el) {
    return null;
  }

  const {
    forkIllustration,
    endpoint,
    newGroupPath,
    projectFullPath,
    visibilityHelpPath,
    cancelPath,
    projectId,
    projectName,
    projectPath,
    projectDefaultBranch,
    projectDescription,
    projectVisibility,
    restrictedVisibilityLevels,
  } = el.dataset;

  return new Vue({
    el,
    name: 'ForkAppRoot',
    apolloProvider: new VueApollo({
      defaultClient: createDefaultClient(),
    }),
    provide: {
      newGroupPath,
      visibilityHelpPath,
      cancelPath,
      endpoint,
      projectFullPath,
      projectId,
      projectName,
      projectPath,
      projectDescription,
      projectDefaultBranch,
      projectVisibility,
      restrictedVisibilityLevels: JSON.parse(restrictedVisibilityLevels),
    },
    render(h) {
      return h(App, {
        props: {
          forkIllustration,
        },
      });
    },
  });
}
