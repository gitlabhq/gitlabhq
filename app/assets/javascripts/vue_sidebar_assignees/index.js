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

    const currentUser = {
      id: parseInt(element.dataset.userId, 10),
      name: element.dataset.name,
      username: element.dataset.username,
    }

    const service = new SidebarAssigneesService(path, field);
    const assignees = new SidebarAssigneesStore(currentUser);

    return {
      assignees,
      service,
    };
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
      <no-assignee v-if="assignees.users.length === 0" :service="service" :assignees="assignees" />
      <single-assignee v-else-if="assignees.users.length === 1" :user="assignees.users[0]" />
      <multiple-assignees v-else :assignees="assignees" />
    </div>
  `,
});


document.addEventListener('DOMContentLoaded', () => {
  window.gl.sidebarAssigneesOptions = new Vue(sidebarAssigneesOptions());
});
