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
    @click="$emit('item-selected', level)"
  >
    <div class="gl-flex gl-flex-col">
      <span class="gl-font-bold">{{ title }}</span>
      <span class="gl-text-sm gl-text-subtle">{{ description }}</span>
    </div>
  </gl-dropdown-item>
</template>
