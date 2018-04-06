import $ from 'jquery';
import Vue from 'vue';

import Translate from '../vue_shared/translate';
import eventHub from './event_hub';
import ProjectsService from './service/projects_service';
import ProjectsStore from './store/projects_store';

import projectsDropdownApp from './components/app.vue';

Vue.use(Translate);

document.addEventListener('DOMContentLoaded', () => {
  const el = document.getElementById('js-projects-dropdown');
  const navEl = document.getElementById('nav-projects-dropdown');

  // Don't do anything if element doesn't exist (No projects dropdown)
  // This is for when the user accesses GitLab without logging in
  if (!el || !navEl) {
    return;
  }

  $(navEl).on('shown.bs.dropdown', () => {
    eventHub.$emit('dropdownOpen');
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    components: {
      projectsDropdownApp,
    },
    data() {
      const dataset = this.$options.el.dataset;
      const store = new ProjectsStore();
      const service = new ProjectsService(dataset.userName);

      const project = {
        id: Number(dataset.projectId),
        name: dataset.projectName,
        namespace: dataset.projectNamespace,
        webUrl: dataset.projectWebUrl,
        avatarUrl: dataset.projectAvatarUrl || null,
        lastAccessedOn: Date.now(),
      };

      return {
        store,
        service,
        state: store.state,
        currentUserName: dataset.userName,
        currentProject: project,
      };
    },
    render(createElement) {
      return createElement('projects-dropdown-app', {
        props: {
          currentUserName: this.currentUserName,
          currentProject: this.currentProject,
          store: this.store,
          service: this.service,
        },
      });
    },
  });
});
