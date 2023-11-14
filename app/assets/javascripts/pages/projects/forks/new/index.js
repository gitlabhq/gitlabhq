import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

const mountElement = document.getElementById('fork-groups-mount-element');

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
} = mountElement.dataset;

Vue.use(VueApollo);

// eslint-disable-next-line no-new
new Vue({
  el: mountElement,
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
