import Vue from 'vue';

import AssigneeTitle from './components/assignee_title';
import NoAssignee from './components/expanded/no_assignee';
import SingleAssignee from './components/expanded/single_assignee';
import MultipleAssignees from './components/expanded/multiple_assignees';

import CollapsedAssignees from './components/collapsed/assignees';

import SidebarAssigneesService from './services/sidebar_assignees_service';
import SidebarAssigneesStore from './stores/sidebar_assignees_store';

const sidebarAssigneesOptions = () => ({
  el: '#js-vue-sidebar-assignees',
  name: 'SidebarAssignees',
  data() {
    const selector = this.$options.el;
    const element = document.querySelector(selector);

    // Get data from data attributes passed from haml
    const rootPath = element.dataset.rootPath;
    const path = element.dataset.path;
    const field = element.dataset.field;
    const editable = element.hasAttribute('data-editable');
    const currentUserId = parseInt(element.dataset.userId, 10);

    const service = new SidebarAssigneesService(path, field);
    const store = new SidebarAssigneesStore(currentUserId, service, rootPath, editable);

    return {
      store,
    };
  },
  computed: {
    numberOfAssignees() {
      return this.store.users.length;
    },
    componentName() {
      switch (this.numberOfAssignees) {
        case 0:
          return 'no-assignee';
        case 1:
          return 'single-assignee';
        default:
          return 'multiple-assignees';
      }
    },
    hideComponent() {
      return !this.store.saved;
    },
  },
  components: {
    'no-assignee': NoAssignee,
    'single-assignee': SingleAssignee,
    'multiple-assignees': MultipleAssignees,
    'assignee-title': AssigneeTitle,
    'collapsed-assignees': CollapsedAssignees,
  },
  template: `
    <div>
      <assignee-title
        :numberOfAssignees="store.users.length"
        :loading="store.loading"
        :editable="store.editable"
      />
      <collapsed-assignees :users="store.users"/>
      <component v-if="store.saved"
        class="value"
        :is="componentName"
        :store="store"
      />
    </div>
  `,
});

document.addEventListener('DOMContentLoaded', () => {
  // Expose this to window so that we can add assignees from glDropdown
  window.gl.sidebarAssigneesOptions = new Vue(sidebarAssigneesOptions());
});
