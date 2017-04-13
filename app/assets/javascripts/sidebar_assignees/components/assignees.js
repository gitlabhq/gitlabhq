import eventHub from '../event_hub';

export default {
  name: 'Assignees',
  data() {
    return {
      defaultRenderCount: 5,
      defaultMaxCounter: 99,
      showLess: true,
    };
  },
  props: {
    rootPath: {
      type: String,
      required: true,
    },
    users: {
      type: Array,
      required: true,
    },
  },
  computed: {
    renderShowMoreSection() {
      return this.users.length > this.defaultRenderCount;
    },
    numberOfHiddenAssignees() {
      return this.users.length - this.defaultRenderCount;
    },
    isHiddenAssignees() {
      return this.numberOfHiddenAssignees > 0;
    },
    collapsedTooltipTitle() {
      const maxRender = Math.min(this.defaultRenderCount, this.users.length);
      const renderUsers = this.users.slice(0, maxRender);
      const names = renderUsers.map(u => u.name);

      if (this.users.length > maxRender) {
        names.push(`+ ${this.users.length - maxRender} more`);
      }

      return names.join(', ');
    },
    sidebarAvatarCounter() {
      let counter = `+${this.users.length - 1}`;

      if (this.users.length > this.defaultMaxCounter) {
        counter = `${this.defaultMaxCounter}+`;
      }

      return counter;
    },
  },
  methods: {
    assignSelf() {
      eventHub.$emit('addCurrentUser');
    },
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    renderAssignee(index) {
      return !this.showLess || (index < this.defaultRenderCount && this.showLess);
    },
    assigneeUrl(user) {
      return `${this.rootPath}${user.username}`;
    },
    assigneeAlt(user) {
      return `${user.name}'s avatar`;
    },
  },
  template: `
    <div>
      <div
        class="sidebar-collapsed-icon sidebar-collapsed-user"
        :class="{ 'multiple-users': users.length > 1, 'has-tooltip': users.length > 0}"
        data-container="body"
        data-placement="left"
        :title="collapsedTooltipTitle"
      >
        <i
          v-if="users.length === 0"
          aria-hidden="true"
          class="fa fa-user"
        />
        <button
          type="button"
          class="btn-link"
          v-for="(user, index) in users"
          v-if="index === 0 || users.length <= 2 && index <= 2"
        >
          <img
            width="24"
            class="avatar avatar-inline s24"
            :alt="assigneeAlt(user)"
            :src="user.avatarUrl"
          >
          <span class="author">{{user.name}}</span>
        </button>
        <button
          v-if="users.length > 2"
          class="btn-link"
          type="button"
        >
          <span
            class="avatar-counter sidebar-avatar-counter"
          >
            {{sidebarAvatarCounter}}
          </span>
        </button>
      </div>
      <div class="value hide-collapsed">
        <template v-if="users.length === 0">
          <span class="assign-yourself no-value">
            No assignee -
            <button
              type="button"
              class="btn-link"
              @click="assignSelf"
            >
              assign yourself
            </button>
          </span>
        </template>
        <template v-else-if="users.length === 1">
          <a
            class="author_link bold"
            :href="assigneeUrl(users[0])"
          >
            <img
              width="32"
              class="avatar avatar-inline s32"
              :alt="assigneeAlt(users[0])"
              :src="users[0].avatarUrl"
            >
            <span class="author">{{users[0].name}}</span>
            <span class="username">@{{users[0].username}}</span>
          </a>
        </template>
        <template v-else>
          <div class="user-list">
            <div
              class="user-item"
              v-for="(user, index) in users"
              v-if="renderAssignee(index)"
            >
              <a
                class="user-link has-tooltip"
                data-placement="bottom"
                :href="assigneeUrl(user)"
                :data-title="user.name"
              >
                <img
                  width="32"
                  class="avatar avatar-inline s32"
                  :alt="assigneeAlt(user)"
                  :src="user.avatarUrl"
                />
              </a>
            </div>
          </div>
          <div
            v-if="renderShowMoreSection"
            class="user-list-more"
          >
            <button
              type="button"
              class="btn-link"
              @click="toggleShowLess"
            >
              <template v-if="showLess">
                + {{numberOfHiddenAssignees}} more
              </template>
              <template v-else>
                - show less
              </template>
            </button>
          </div>
        </template>
      </div>
    </div>
  `,
};
