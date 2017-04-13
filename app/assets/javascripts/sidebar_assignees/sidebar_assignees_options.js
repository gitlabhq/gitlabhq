/* global Flash */

import eventHub from './event_hub';

import AssigneeTitle from './components/assignee_title';
import Assignees from './components/assignees';

import SidebarAssigneesService from './services/sidebar_assignees_service';
import SidebarAssigneesStore from './stores/sidebar_assignees_store';

export default {
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
    const store = new SidebarAssigneesStore({
      currentUserId,
      rootPath,
      editable,
      assignees: gl.sidebarAssigneesData,
    });

    return {
      loading: false,
      store,
      service,
    };
  },
  computed: {
    numberOfAssignees() {
      return this.store.users.length;
    },
  },
  created() {
    eventHub.$on('addCurrentUser', this.addCurrentUser);
    eventHub.$on('addUser', this.store.addUserId.bind(this.store));
    eventHub.$on('removeUser', this.store.removeUserId.bind(this.store));
    eventHub.$on('removeAllUsers', this.store.removeAllUserIds.bind(this.store));
    eventHub.$on('saveUsers', this.saveUsers);
  },
  methods: {
    addCurrentUser() {
      this.store.addCurrentUserId();

      // Notify gl dropdown that we are now assigning to current user
      this.$el.parentElement.dispatchEvent(new Event('assignYourself'));

      this.saveUsers();
    },
    saveUsers() {
      this.loading = true;
      this.service.update(this.store.getUserIds())
        .then((response) => {
          this.loading = false;
          this.store.setUsers(response.data.assignees);
        })
        .catch(() => {
          this.loading = false;
          return new Flash('An error occured while saving assignees');
        });
    },
  },
  components: {
    'assignee-title': AssigneeTitle,
    'assignees': Assignees,
  },
  template: `
    <div>
      <assignee-title
        :numberOfAssignees="store.selectedUserIds.length"
        :loading="loading"
        :editable="store.editable"
      />
      <assignees
        class="value"
        v-if="!store.loading"
        :rootPath="store.rootPath"
        :users="store.renderedUsers"
      />
    </div>
  `,
};
