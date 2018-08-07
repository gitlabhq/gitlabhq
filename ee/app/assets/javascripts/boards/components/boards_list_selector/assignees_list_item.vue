<script>
import { sprintf, __ } from '~/locale';

export default {
  props: {
    item: {
      type: Object,
      required: true,
    },
  },
  computed: {
    avatarAltText() {
      return sprintf(__("%{name}'s avatar"), {
        name: this.item.name,
      });
    },
  },
  methods: {
    handleItemClick() {
      this.$emit('onItemSelect', this.item);
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
          :src="item.avatar_url"
          class="avatar s32 lazy"
        />
      </div>
      <div class="dropdown-user-details">
        <div :title="item.name">{{ item.name }}</div>
        <div
          :title="item.username"
          class="dropdown-light-content"
        >@{{ item.username }}</div>
      </div>
    </button>
  </li>
</template>
