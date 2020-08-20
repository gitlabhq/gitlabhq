<script>
import { GlDeprecatedDropdown, GlDeprecatedDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDeprecatedDropdown,
    GlDeprecatedDropdownItem,
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
    <gl-deprecated-dropdown
      right
      text="Use an existing commit message"
      variant="link"
      class="mr-commit-dropdown"
    >
      <gl-deprecated-dropdown-item
        v-for="commit in commits"
        :key="commit.short_id"
        class="text-nowrap text-truncate"
        @click="$emit('input', commit.message)"
      >
        <span class="monospace mr-2">{{ commit.short_id }}</span> {{ commit.title }}
      </gl-deprecated-dropdown-item>
    </gl-deprecated-dropdown>
  </div>
</template>
