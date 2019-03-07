<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    commits: {
      type: Array,
      required: true,
      default: () => [],
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown
      right
      text="Use an existing commit message"
      variant="link"
      class="mr-commit-dropdown"
    >
      <gl-dropdown-item
        v-for="commit in commits"
        :key="commit.short_id"
        class="text-nowrap text-truncate"
        @click="$emit('input', commit.message)"
      >
        <span class="monospace mr-2">{{ commit.short_id }}</span> {{ commit.title }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
