import Vue from 'vue';
import ForkForm from './components/fork_form.vue';
import ForkGroupsList from './components/fork_groups_list.vue';

const mountElement = document.getElementById('fork-groups-mount-element');

if (gon.features.forkProjectForm) {
  const {
    endpoint,
    newGroupPath,
    projectFullPath,
    visibilityHelpPath,
    projectId,
    projectName,
    projectPath,
    projectDescription,
    projectVisibility,
  } = mountElement.dataset;

  // eslint-disable-next-line no-new
  new Vue({
    el: mountElement,
    render(h) {
      return h(ForkForm, {
        props: {
          endpoint,
          newGroupPath,
          projectFullPath,
          visibilityHelpPath,
          projectId,
          projectName,
          projectPath,
          projectDescription,
          projectVisibility,
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
