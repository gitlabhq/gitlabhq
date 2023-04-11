<script>
import { GlBadge, GlDisclosureDropdown } from '@gitlab/ui';

export default {
  components: {
    GlBadge,
    GlDisclosureDropdown,
  },
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :items="items"
    placement="center"
    @shown="$emit('shown')"
    @hidden="$emit('hidden')"
  >
    <template #toggle>
      <slot></slot>
    </template>
    <template #list-item="{ item }">
      <span class="gl-display-flex gl-align-items-center gl-justify-content-space-between">
        {{ item.text }}
        <gl-badge pill size="sm" variant="neutral">{{ item.count || 0 }}</gl-badge>
      </span>
    </template>
  </gl-disclosure-dropdown>
</template>
