<script>
import { GlBadge, GlDisclosureDropdown } from '@gitlab/ui';
import { userCounts } from '~/super_sidebar/user_counts_manager';

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
  methods: {
    getCount(item) {
      return userCounts[item.userCount] ?? item.count ?? 0;
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :items="items"
    placement="bottom"
    @shown="$emit('shown')"
    @hidden="$emit('hidden')"
  >
    <template #toggle>
      <slot></slot>
    </template>
    <template #list-item="{ item }">
      <span class="gl-flex gl-items-center gl-justify-between">
        {{ item.text }}
        <gl-badge pill variant="neutral">{{ getCount(item) }}</gl-badge>
      </span>
    </template>
  </gl-disclosure-dropdown>
</template>
