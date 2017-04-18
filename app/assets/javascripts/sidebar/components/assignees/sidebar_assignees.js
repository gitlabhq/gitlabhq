import AssigneeTitle from './assignee_title';
import Assignees from './assignees';

import store from '../../stores/sidebar_store';
import mediator from '../../sidebar_mediator';

import eventHub from '../../event_hub';

export default {
  name: 'SidebarAssignees',
  data() {
    return {
      store,
      loading: false,
      field: '',
    };
  },
  components: {
    'assignee-title': AssigneeTitle,
    'assignees': Assignees,
  },
  computed: {
    numberOfAssignees() {
      return this.store.selectedUserIds.length;
    },
  },
  methods: {
    assignSelf() {
      // Notify gl dropdown that we are now assigning to current user
      this.$el.parentElement.dispatchEvent(new Event('assignYourself'));

      mediator.assignYourself();
      this.saveUsers();
    },
    saveUsers() {
      this.loading = true;
      mediator.saveSelectedUsers(this.field).then(() => this.loading = false);
    }
  },
  created() {
    // Get events from glDropdown
    eventHub.$on('sidebar:removeUser', this.store.removeUserId.bind(this.store));
    eventHub.$on('sidebar:addUser', this.store.addUserId.bind(this.store));
    eventHub.$on('sidebar:removeAllUsers', this.store.removeAllUserIds.bind(this.store));
    eventHub.$on('sidebar:saveUsers', this.saveUsers);
  },
  beforeMount() {
    const element = this.$el;
    this.field = element.dataset.field;
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
        v-if="!loading"
        :rootPath="store.rootPath"
        :users="store.renderedUsers"
        @assignSelf="assignSelf"
      />
    </div>
  `,
};
