import Vue from 'vue';
import eventHub from './event_hub';

import AssigneeTitle from './components/assignee_title';
import NoAssignee from './components/expanded/no_assignee';
import SingleAssignee from './components/expanded/single_assignee';
import MultipleAssignees from './components/expanded/multiple_assignees';

import CollapsedAssignees from './components/collapsed/assignees';

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
    const currentUser = {
      id: parseInt(element.dataset.userId, 10),
      name: element.dataset.userName,
      username: element.dataset.userUserName,
      avatarUrl: element.dataset.avatar_url,
    };

    const service = new SidebarAssigneesService(path, field);
    const store = new SidebarAssigneesStore({
      currentUser,
      rootPath,
      editable,
      assignees: gl.sidebarAssigneesData,
    });

    return {
      store,
      service,
      loading: false,
    };
  },
  computed: {
    numberOfAssignees() {
      return this.store.users.length;
    },
  },
  created() {
    eventHub.$on('addCurrentUser', this.addCurrentUser);
    eventHub.$on('addUser', this.store.addUser.bind(this.store));
    eventHub.$on('removeUser', this.store.removeUser.bind(this.store));
    eventHub.$on('removeAllUsers', this.store.removeAllUsers.bind(this.store));
    eventHub.$on('saveUsers', this.saveUsers);
  },
  methods: {
    addCurrentUser() {
      this.store.addCurrentUser();
      this.saveUsers();
    },
    saveUsers() {
      this.loading = true;
      this.service.update(this.store.getUserIds())
        .then((response) => {
          this.loading = false;
          this.store.saveUsers(response.data.assignees);
        }).catch(() => {
          this.loading = false;
          return new Flash('An error occured while saving assignees', 'alert');
        });
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
        :loading="loading"
        :editable="store.editable"
      />
      <collapsed-assignees :users="store.users"/>

      <div class="value" v-if="!loading">
        <no-assignee v-if="numberOfAssignees === 0" />
        <single-assignee
          v-else-if="numberOfAssignees === 1"
          :rootPath="store.rootPath"
          :user="store.users[0]"
        />
        <multiple-assignees
          v-else
          :rootPath="store.rootPath"
          :users="store.users"
        />
      </div>
    </div>
  `,
};
