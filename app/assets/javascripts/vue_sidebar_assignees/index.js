import Vue from 'vue';

import AssigneeTitle from './components/assignee_title';
import NoAssignee from './components/expanded/no_assignee';
import SingleAssignee from './components/expanded/single_assignee';
import MultipleAssignees from './components/expanded/multiple_assignees';

import CollapsedNoAssignee from './components/collapsed/no_assignee';
import CollapsedSingleAssignee from './components/collapsed/single_assignee';
import CollapsedTwoAssignees from './components/collapsed/two_assignees';
import CollapsedMultipleAssignees from './components/collapsed/multiple_assignees';

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
    const editable = element.hasAttribute('data-editable');
    const currentUserId = parseInt(element.dataset.userId, 10);

    const service = new SidebarAssigneesService(path, field);
    const assignees = new SidebarAssigneesStore(currentUserId, service, editable);

    return {
      assignees,
    };
  },
  computed: {
    numberOfAssignees() {
      return this.assignees.users.length;
    },
    componentName() {
      if (this.numberOfAssignees === 0) {
        return 'no-assignee';
      } else if (this.numberOfAssignees === 1) {
        return 'single-assignee';
      } else {
        return 'multiple-assignees';
      }
    },
    hideComponent() {
      return !this.assignees.saved;
    },
    collapsedComponentName() {
      if (this.numberOfAssignees === 0) {
        return 'collapsed-no-assignee';
      } else if (this.numberOfAssignees === 1) {
        return 'collapsed-single-assignee';
      } else if (this.numberOfAssignees === 2) {
        return 'collapsed-two-assignees';
      } else {
        return 'collapsed-multiple-assignees';
      }
    },
  },
  components: {
    'no-assignee': NoAssignee,
    'single-assignee': SingleAssignee,
    'multiple-assignees': MultipleAssignees,
    'assignee-title': AssigneeTitle,
    'collapsed-single-assignee': CollapsedSingleAssignee,
    'collapsed-no-assignee': CollapsedNoAssignee,
    'collapsed-two-assignees': CollapsedTwoAssignees,
    'collapsed-multiple-assignees': CollapsedMultipleAssignees,
  },
  template: `
    <div>
      <component :is="collapsedComponentName" :users="assignees.users" />
      <assignee-title :numberOfAssignees="assignees.users.length" :loading="assignees.loading" :editable="assignees.editable"/>
      <component class="value" :is="componentName" :assignees="assignees" :class="{ hidden: hideComponent }" />
    </div>
  `,
});


document.addEventListener('DOMContentLoaded', () => {
  window.gl.sidebarAssigneesOptions = new Vue(sidebarAssigneesOptions());
});
