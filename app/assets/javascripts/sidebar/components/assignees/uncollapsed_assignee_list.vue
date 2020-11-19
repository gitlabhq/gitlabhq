<script>
import { __, sprintf } from '~/locale';
import AssigneeAvatarLink from './assignee_avatar_link.vue';

const DEFAULT_RENDER_COUNT = 5;

export default {
  components: {
    AssigneeAvatarLink,
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
  },
  data() {
    return {
      showLess: true,
    };
  },
  computed: {
    firstUser() {
      return this.users[0];
    },
    hasOneUser() {
      return this.users.length === 1;
    },
    hiddenAssigneesLabel() {
      const { numberOfHiddenAssignees } = this;
      return sprintf(__('+ %{numberOfHiddenAssignees} more'), { numberOfHiddenAssignees });
    },
    renderShowMoreSection() {
      return this.users.length > DEFAULT_RENDER_COUNT;
    },
    numberOfHiddenAssignees() {
      return this.users.length - DEFAULT_RENDER_COUNT;
    },
    uncollapsedUsers() {
      const uncollapsedLength = this.showLess
        ? Math.min(this.users.length, DEFAULT_RENDER_COUNT)
        : this.users.length;
      return this.showLess ? this.users.slice(0, uncollapsedLength) : this.users;
    },
    username() {
      return `@${this.firstUser.username}`;
    },
  },
  methods: {
    toggleShowLess() {
      this.showLess = !this.showLess;
    },
  },
};
</script>

<template>
  <assignee-avatar-link
    v-if="hasOneUser"
    tooltip-placement="left"
    :tooltip-has-name="false"
    :user="firstUser"
    :issuable-type="issuableType"
  >
    <div class="ml-2 gl-line-height-normal">
      <div>{{ firstUser.name }}</div>
      <div>{{ username }}</div>
    </div>
  </assignee-avatar-link>
  <div v-else>
    <div class="user-list">
      <div v-for="user in uncollapsedUsers" :key="user.id" class="user-item">
        <assignee-avatar-link :user="user" :issuable-type="issuableType" />
      </div>
    </div>
    <div v-if="renderShowMoreSection" class="user-list-more">
      <button
        type="button"
        class="btn-link"
        data-qa-selector="more_assignees_link"
        @click="toggleShowLess"
      >
        <template v-if="showLess">
          {{ hiddenAssigneesLabel }}
        </template>
        <template v-else>{{ __('- show less') }}</template>
      </button>
    </div>
  </div>
</template>
