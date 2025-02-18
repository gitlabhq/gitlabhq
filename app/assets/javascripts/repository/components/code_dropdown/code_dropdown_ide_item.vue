<script>
import { GlButton, GlButtonGroup, GlDisclosureDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlDisclosureDropdownItem,
  },
  props: {
    ideItem: {
      type: Object,
      required: true,
    },
  },
  methods: {
    closeDropdown() {
      this.$emit('close-dropdown');
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item
    v-if="ideItem.items"
    class="gl-mb-3 gl-flex gl-w-full gl-items-center gl-justify-between gl-px-4 gl-py-2"
  >
    <span class="gl-min-w-0">{{ ideItem.text }}</span>
    <gl-button-group>
      <gl-button
        v-for="(ideOption, ideOptionIndex) in ideItem.items"
        :key="ideOptionIndex"
        :href="ideOption.href"
        is-unsafe-link
        target="_blank"
        size="small"
        @click="closeDropdown"
      >
        {{ ideOption.text }}
      </gl-button>
    </gl-button-group>
  </gl-disclosure-dropdown-item>
  <gl-disclosure-dropdown-item v-else-if="ideItem.href" :item="ideItem" @action="closeDropdown" />
</template>
