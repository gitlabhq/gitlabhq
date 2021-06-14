import Vue from 'vue';
import App from './components/app.vue';
import ForkGroupsList from './components/fork_groups_list.vue';

const mountElement = document.getElementById('fork-groups-mount-element');

if (gon.features.forkProjectForm) {
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
    },
    render(h) {
      return h(App, {
        props: {
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
          restrictedVisibilityLevels: JSON.parse(restrictedVisibilityLevels),
        },
      });
    },
  });
} else {
  const { endpoint } = mountElement.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: mountElement,
    render(h) {
      return h(ForkGroupsList, {
        props: {
          endpoint,
        },
      });
    },
  });
}
