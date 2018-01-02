import Vue from 'vue';

import Translate from '../vue_shared/translate';
import eventHub from './event_hub';
import ProjectsService from './service/projects_service';
import ProjectsStore from './store/projects_store';

import projectsDropdownApp from './components/app.vue';

Vue.use(Translate);

const el = document.getElementById('js-projects-dropdown');
const navEl = document.getElementById('nav-projects-dropdown');

function dropdownOpened(e) {
  const dropdownEl = $(e.currentTarget).find('.projects-dropdown-menu');
  dropdownEl.one('transitionend', () => {
    eventHub.$emit('dropdownOpen');
  });
}

$(navEl).on('show.bs.dropdown', (e) => {
  dropdownOpened(e);
});

// eslint-disable-next-line no-new, no-unused-expressions
(el && navEl) && new Vue({ // If elements are not in the DOM do nothing
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

export default dropdownOpened;
