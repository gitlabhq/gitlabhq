<script>
import { GlDropdownItem } from '@gitlab/ui';

export default {
  name: 'NotificationsDropdownItem',
  components: {
    GlDropdownItem,
  },
  props: {
    level: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      required: true,
    },
    notificationLevel: {
      type: String,
      required: true,
    },
  },
  computed: {
    isActive() {
      return this.notificationLevel === this.level;
    },
  },
};
</script>

<template>
  <gl-dropdown-item
    is-check-item
    :is-checked="isActive"
    :class="{ 'is-active': isActive }"
    data-testid="notification-item"
    @click="$emit('item-selected', level)"
  >
    <div class="gl-display-flex gl-flex-direction-column">
      <span class="gl-font-weight-bold">{{ title }}</span>
      <span class="gl-text-gray-500">{{ description }}</span>
    </div>
  </gl-dropdown-item>
</template>
