import Vue from 'vue';

import AssigneeTitle from './components/assignee_title';
import NoAssignee from './components/no_assignee';
import SingleAssignee from './components/single_assignee';
import MultipleAssignees from './components/multiple_assignees';

import SidebarAssigneesService from './services/sidebar_assignees_service';
import SidebarAssigneesStore from './stores/sidebar_assignees_store';

const sidebarAssigneesOptions = () => ({
  el: '#js-vue-sidebar-assignees',
  name: 'SidebarAssignees',
  data() {
    const selector = this.$options.el;
    const element = document.querySelector(selector);
    const path = element.dataset.path;
    const field = element.dataset.field;
    const currentUserId = parseInt(element.dataset.userId, 10);

    const service = new SidebarAssigneesService(path, field);
    const assignees = new SidebarAssigneesStore(currentUserId, service);

    return {
      assignees,
    };
  },
  computed: {
    componentName() {
      const numberOfAssignees = this.assignees.users.length;

      if (numberOfAssignees === 0) {
        return 'no-assignee';
      } else if (numberOfAssignees === 1) {
        return 'single-assignee';
      } else {
        return 'multiple-assignees';
      }
    },
  },
  components: {
    'no-assignee': NoAssignee,
    'single-assignee': SingleAssignee,
    'multiple-assignees': MultipleAssignees,
    'assignee-title': AssigneeTitle,
  },
  template: `
    <div class="sidebar-assignees">
      <assignee-title :numberOfAssignees="assignees.users.length" />
      <component :is="componentName" :assignees="assignees" />
    </div>
  `,
});


document.addEventListener('DOMContentLoaded', () => {
  window.gl.sidebarAssigneesOptions = new Vue(sidebarAssigneesOptions());
});
