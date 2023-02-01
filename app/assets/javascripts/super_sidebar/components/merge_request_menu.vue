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
  methods: {
    navigate() {
      this.$refs.link.click();
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown :items="items" placement="center" @action="navigate">
    <template #toggle>
      <slot></slot>
    </template>
    <template #list-item="{ item }">
      <a
        ref="link"
        class="gl-display-flex gl-align-items-center gl-justify-content-space-between gl-hover-text-gray-900 gl-hover-text-decoration-none gl-text-gray-900"
        :href="item.href"
        tabindex="-1"
      >
        {{ item.text }}
        <gl-badge pill size="sm" variant="neutral">{{ item.count || 0 }}</gl-badge>
      </a>
    </template>
  </gl-disclosure-dropdown>
</template>
