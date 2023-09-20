<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
  },
};
</script>

<template>
  <div class="gl-ml-5">
    <gl-disclosure-dropdown
      category="tertiary"
      toggle-class="btn-icon btn-sm"
      icon="ellipsis_v"
      data-testid="work_items_links_menu"
      :aria-label="__(`More actions`)"
      text-sr-only
      no-caret
    >
      <gl-disclosure-dropdown-item @action="$emit('removeChild')">
        <template #list-item>{{ s__('WorkItem|Remove') }}</template>
      </gl-disclosure-dropdown-item>
    </gl-disclosure-dropdown>
  </div>
</template>
