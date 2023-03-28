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
  <div class="gl-ml-5">
    <gl-dropdown
      category="tertiary"
      toggle-class="btn-icon btn-sm"
      :right="true"
      data-testid="work_items_links_menu"
    >
      <template #button-content>
        <gl-icon name="ellipsis_v" :size="14" />
      </template>
      <gl-dropdown-item @click="$emit('removeChild')">
        {{ s__('WorkItem|Remove') }}
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
