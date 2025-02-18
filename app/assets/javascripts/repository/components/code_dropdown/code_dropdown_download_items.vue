<script>
import { GlButton, GlButtonGroup, GlDisclosureDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlDisclosureDropdownItem,
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
  <gl-disclosure-dropdown-item v-if="items.length" class="gl-px-3 gl-py-2">
    <gl-button-group class="gl-w-full">
      <gl-button
        v-for="(item, index) in items"
        :key="index"
        :href="item.href"
        v-bind="item.extraAttrs"
        @click="$emit('close-dropdown')"
      >
        {{ item.text }}
      </gl-button>
    </gl-button-group>
  </gl-disclosure-dropdown-item>
</template>
