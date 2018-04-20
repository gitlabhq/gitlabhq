<script>
import { __ } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';

export default {
  name: 'Assignees',
  directives: {
    tooltip,
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
    editable: {
      type: Boolean,
      required: true,
    },
    issuableType: {
      type: String,
      require: true,
      default: 'issue',
    },
  },
  data() {
    return {
      defaultRenderCount: 5,
      defaultMaxCounter: 99,
      showLess: true,
    };
  },
  computed: {
    firstUser() {
      return this.users[0];
    },
    hasMoreThanTwoAssignees() {
      return this.users.length > 2;
    },
    hasMoreThanOneAssignee() {
      return this.users.length > 1;
    },
    hasAssignees() {
      return this.users.length > 0;
    },
    hasNoUsers() {
      return !this.users.length;
    },
    hasOneUser() {
      return this.users.length === 1;
    },
    renderShowMoreSection() {
      return this.users.length > this.defaultRenderCount;
    },
    numberOfHiddenAssignees() {
      return this.users.length - this.defaultRenderCount;
    },
    isHiddenAssignees() {
      return this.numberOfHiddenAssignees > 0;
    },
    hiddenAssigneesLabel() {
      return `+ ${this.numberOfHiddenAssignees} more`;
    },
    collapsedTooltipTitle() {
      const maxRender = Math.min(this.defaultRenderCount, this.users.length);
      const renderUsers = this.users.slice(0, maxRender);
      const names = renderUsers.map(u => u.name);

      if (this.users.length > maxRender) {
        names.push(`+ ${this.users.length - maxRender} more`);
      }

      if (!this.users.length) {
        const emptyTooltipLabel = this.issuableType === 'issue' ?
          __('Assignee(s)') : __('Assignee');
        names.push(emptyTooltipLabel);
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
      this.$emit('assign-self');
    },
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
    renderAssignee(index) {
      return !this.showLess || (index < this.defaultRenderCount && this.showLess);
    },
    avatarUrl(user) {
      return user.avatar || user.avatar_url || gon.default_avatar_url;
    },
    assigneeUrl(user) {
      return `${this.rootPath}${user.username}`;
    },
    assigneeAlt(user) {
      return `${user.name}'s avatar`;
    },
    assigneeUsername(user) {
      return `@${user.username}`;
    },
    shouldRenderCollapsedAssignee(index) {
      const firstTwo = this.users.length <= 2 && index <= 2;

      return index === 0 || firstTwo;
    },
  },
};
</script>

<template>
  <div>
    <div
      class="sidebar-collapsed-icon sidebar-collapsed-user"
      :class="{ 'multiple-users': hasMoreThanOneAssignee }"
      v-tooltip
      data-container="body"
      data-placement="left"
      :title="collapsedTooltipTitle"
    >
      <i
        v-if="hasNoUsers"
        aria-label="No Assignee"
        class="fa fa-user"
      >
      </i>
      <button
        type="button"
        class="btn-link"
        v-for="(user, index) in users"
        v-if="shouldRenderCollapsedAssignee(index)"
        :key="user.id"
      >
        <img
          width="24"
          class="avatar avatar-inline s24"
          :alt="assigneeAlt(user)"
          :src="avatarUrl(user)"
        />
        <span class="author">
          {{ user.name }}
        </span>
      </button>
      <button
        v-if="hasMoreThanTwoAssignees"
        class="btn-link"
        type="button"
      >
        <span
          class="avatar-counter sidebar-avatar-counter"
        >
          {{ sidebarAvatarCounter }}
        </span>
      </button>
    </div>
    <div class="value hide-collapsed">
      <template v-if="hasNoUsers">
        <span class="assign-yourself no-value">
          No assignee
          <template v-if="editable">
            -
            <button
              type="button"
              class="btn-link"
              @click="assignSelf"
            >
              assign yourself
            </button>
          </template>
        </span>
      </template>
      <template v-else-if="hasOneUser">
        <a
          class="author_link bold"
          :href="assigneeUrl(firstUser)"
        >
          <img
            width="32"
            class="avatar avatar-inline s32"
            :alt="assigneeAlt(firstUser)"
            :src="avatarUrl(firstUser)"
          />
          <span class="author">
            {{ firstUser.name }}
          </span>
          <span class="username">
            {{ assigneeUsername(firstUser) }}
          </span>
        </a>
      </template>
      <template v-else>
        <div class="user-list">
          <div
            class="user-item"
            v-for="(user, index) in users"
            v-if="renderAssignee(index)"
            :key="user.id"
          >
            <a
              class="user-link has-tooltip"
              data-container="body"
              data-placement="bottom"
              :href="assigneeUrl(user)"
              :data-title="user.name"
            >
              <img
                width="32"
                class="avatar avatar-inline s32"
                :alt="assigneeAlt(user)"
                :src="avatarUrl(user)"
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
              {{ hiddenAssigneesLabel }}
            </template>
            <template v-else>
              - show less
            </template>
          </button>
        </div>
      </template>
    </div>
  </div>
</template>

