<script>
import { GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdownItem,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    active: {
      type: Boolean,
      required: true,
    },
  },
  methods: {
    isActive(name) {
      return this.alert.assignees.nodes.some(({ username }) => username === name);
    },
  },
};
</script>

<template>
  <gl-dropdown-item
    :key="user.username"
    data-testid="assigneeDropdownItem"
    class="assignee-dropdown-item gl-vertical-align-middle"
    :active="active"
    active-class="is-active"
    @click="$emit('update-alert-assignees', user.username)"
  >
    <span class="gl-relative mr-2">
      <img
        :alt="user.username"
        :src="user.avatar_url"
        :width="32"
        class="avatar avatar-inline gl-m-0 s32"
        data-qa-selector="avatar_image"
      />
    </span>
    <span class="d-flex gl-flex-direction-column gl-overflow-hidden">
      <strong class="dropdown-menu-user-full-name">
        {{ user.name }}
      </strong>
      <span class="dropdown-menu-user-username"> {{ user.username }}</span>
    </span>
  </gl-dropdown-item>
</template>
