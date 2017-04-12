import CollapsedAvatar from './avatar';

export default {
  name: 'CollapsedAssignees',
  data() {
    return {
      defaultRenderCount: 5,
      defaultMaxCounter: 99,
    };
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
  },
  computed: {
    title() {
      const maxRender = Math.min(this.defaultRenderCount, this.users.length);
      const renderUsers = this.users.slice(0, maxRender);
      const names = [];

      renderUsers.forEach(u => names.push(u.name));

      if (this.users.length > maxRender) {
        names.push(`+ ${this.users.length - maxRender} more`);
      }

      return names.join(', ');
    },
    counter() {
      let counter = `+${this.users.length - 1}`;

      if (this.users.length > this.defaultMaxCounter) {
        counter = `${this.defaultMaxCounter}+`;
      }

      return counter;
    },
    hasNoAssignees() {
      return this.users.length === 0;
    },
    hasTwoAssignees() {
      return this.users.length === 2;
    },
    moreThanOneAssignees() {
      return this.users.length > 1;
    },
    moreThanTwoAssignees() {
      return this.users.length > 2;
    },
  },
  components: {
    'collapsed-avatar': CollapsedAvatar,
  },
  template: `
    <div>
      <div v-if="hasNoAssignees" class="sidebar-collapsed-icon sidebar-collapsed-user">
        <i aria-hidden="true" class="fa fa-user"></i>
      </div>
      <div v-else class="sidebar-collapsed-icon sidebar-collapsed-user"
          :class="{'multiple-users': moreThanOneAssignees}"
          data-container="body"
          data-placement="left"
          data-toggle="tooltip"
          :data-original-title="title" >
        <collapsed-avatar
          :name="users[0].name"
          :avatarUrl="users[0].avatarUrl"
        />
        <collapsed-avatar
          v-if="hasTwoAssignees"
          :name="users[1].name"
          :avatarUrl="users[1].avatarUrl"
        />
        <button class="btn-link" type="button" v-if="moreThanTwoAssignees">
          <span class="avatar-counter sidebar-avatar-counter">{{counter}}</span>
        </button>
      </div>
    </div>
  `,
};
