import AssigneeTitle from './assignee_title';
import Assignees from './assignees';

import Store from '../../stores/sidebar_store';
import Mediator from '../../sidebar_mediator';

import eventHub from '../../event_hub';

export default {
  name: 'SidebarAssignees',
  data() {
    return {
      mediator: new Mediator(),
      store: new Store(),
      loading: false,
      field: '',
    };
  },
  components: {
    'assignee-title': AssigneeTitle,
    assignees: Assignees,
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

      this.mediator.assignYourself();
      this.saveUsers();
    },
    saveUsers() {
      this.loading = true;

      function setLoadingFalse() {
        this.loading = false;
      }

      this.mediator.saveSelectedUsers(this.field)
        .then(setLoadingFalse)
        .catch(setLoadingFalse);
    },
  },
  created() {
    // Get events from glDropdown
    eventHub.$on('sidebar.removeUser', this.store.removeUserId.bind(this.store));
    eventHub.$on('sidebar.addUser', this.store.addUserId.bind(this.store));
    eventHub.$on('sidebar.removeAllUsers', this.store.removeAllUserIds.bind(this.store));
    eventHub.$on('sidebar.saveUsers', this.saveUsers);
  },
  beforeMount() {
    this.field = this.$el.dataset.field;
  },
  template: `
    <div>
      <assignee-title
        :number-of-assignees="store.selectedUserIds.length"
        :loading="loading"
        :editable="store.editable"
      />
      <assignees
        class="value"
        v-if="!loading"
        :root-path="store.rootPath"
        :users="store.renderedUsers"
      />
    </div>
  `,
};
