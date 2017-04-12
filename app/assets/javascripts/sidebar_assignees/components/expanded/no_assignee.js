import eventHub from '../../event_hub';

export default {
  name: 'NoAssignee',
  methods: {
    assignSelf() {
      eventHub.$emit('addCurrentUser');
    },
  },
  template: `
    <div class="hide-collapsed">
      <span class="assign-yourself no-value">
        No assignee -
        <button type="button" class="btn-link" @click="assignSelf">
          assign yourself
        </button>
      </span>
    </div>
  `,
};
