<script>
import { GlIcon, GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdownItem,
    GlDropdown,
    GlIcon,
  },
};
</script>

<template>
  <span class="gl-ml-2">
    <gl-dropdown category="tertiary" toggle-class="btn-icon" :right="true">
      <template #button-content>
        <gl-icon name="ellipsis_v" :size="14" />
      </template>
      <gl-dropdown-item @click="$emit('removeChild')">
        {{ s__('WorkItem|Remove') }}
      </gl-dropdown-item>
    </gl-dropdown>
  </span>
</template>
