import Vue from 'vue';
import App from './components/app.vue';

const mountElement = document.getElementById('fork-groups-mount-element');

const {
  forkIllustration,
  endpoint,
  newGroupPath,
  projectFullPath,
  visibilityHelpPath,
  projectId,
  projectName,
  projectPath,
  projectDescription,
  projectVisibility,
  restrictedVisibilityLevels,
} = mountElement.dataset;

// eslint-disable-next-line no-new
new Vue({
  el: mountElement,
  provide: {
    newGroupPath,
    visibilityHelpPath,
    endpoint,
    projectFullPath,
    projectId,
    projectName,
    projectPath,
    projectDescription,
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
