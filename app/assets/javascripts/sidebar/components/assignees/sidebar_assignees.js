/* global Flash */

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
  methods: {
    assignSelf() {
      // Notify gl dropdown that we are now assigning to current user
      this.$el.parentElement.dispatchEvent(new Event('assignYourself'));

      this.mediator.assignYourself();
      this.saveAssignees();
    },
    saveAssignees() {
      this.loading = true;

      function setLoadingFalse() {
        this.loading = false;
      }

      this.mediator.saveAssignees(this.field)
        .then(setLoadingFalse.bind(this))
        .catch(() => {
          setLoadingFalse();
          return new Flash('Error occurred when saving assignees');
        });
    },
  },
  created() {
    this.removeAssignee = this.store.removeAssignee.bind(this.store);
    this.addAssignee = this.store.addAssignee.bind(this.store);
    this.removeAllAssignees = this.store.removeAllAssignees.bind(this.store);

    // Get events from glDropdown
    eventHub.$on('sidebar.removeAssignee', this.removeAssignee);
    eventHub.$on('sidebar.addAssignee', this.addAssignee);
    eventHub.$on('sidebar.removeAllAssignees', this.removeAllAssignees);
    eventHub.$on('sidebar.saveAssignees', this.saveAssignees);
  },
  beforeDestroy() {
    eventHub.$off('sidebar.removeAssignee', this.removeAssignee);
    eventHub.$off('sidebar.addAssignee', this.addAssignee);
    eventHub.$off('sidebar.removeAllAssignees', this.removeAllAssignees);
    eventHub.$off('sidebar.saveAssignees', this.saveAssignees);
  },
  beforeMount() {
    this.field = this.$el.dataset.field;
    this.signedIn = typeof this.$el.dataset.signedIn !== 'undefined';
  },
  template: `
    <div>
      <assignee-title
        :number-of-assignees="store.assignees.length"
        :loading="loading || store.isFetching.assignees"
        :editable="store.editable"
        :show-toggle="!signedIn"
      />
      <assignees
        v-if="!store.isFetching.assignees"
        class="value"
        :root-path="store.rootPath"
        :users="store.assignees"
        :editable="store.editable"
        @assign-self="assignSelf"
      />
    </div>
  `,
};
