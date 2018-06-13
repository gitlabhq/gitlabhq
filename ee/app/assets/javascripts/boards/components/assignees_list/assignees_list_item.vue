<script>
import { sprintf, __ } from '~/locale';

export default {
  props: {
    assignee: {
      type: Object,
      required: true,
    },
  },
  computed: {
    avatarAltText() {
      return sprintf(__("%{name}'s avatar"), {
        name: this.assignee.name,
      });
    },
  },
  methods: {
    handleItemClick() {
      this.$emit('onItemSelect', this.assignee);
    },
  },
};
</script>

<template>
  <li
    class="filter-dropdown-item"
    @click="handleItemClick"
  >
    <button
      class="btn btn-link dropdown-user"
      type="button"
    >
      <div class="avatar-container s32">
        <img
          :alt="avatarAltText"
          :src="assignee.avatar_url"
          class="avatar s32 lazy"
        />
      </div>
      <div class="dropdown-user-details">
        <div :title="assignee.name">{{ assignee.name }}</div>
        <div
          :title="assignee.username"
          class="dropdown-light-content"
        >@{{ assignee.username }}</div>
      </div>
    </button>
  </li>
</template>
