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
    :active="active"
    active-class="is-active"
    :avatar-url="user.avatar_url"
    :secondary-text="`@${user.username}`"
    @click="$emit('update-alert-assignees', user.username)"
  >
    {{ user.name }}
  </gl-dropdown-item>
</template>
