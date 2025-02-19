<script>
import { GlButton, GlButtonGroup, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shouldDisableShortcuts } from '~/behaviors/shortcuts/shortcuts_toggle';
import { InternalEvents } from '~/tracking';

export default {
  components: {
    GlButton,
    GlButtonGroup,
    GlDisclosureDropdownItem,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    ideItem: {
      type: Object,
      required: true,
    },
  },
  computed: {
    shortcutsDisabled() {
      return shouldDisableShortcuts();
    },
  },
  methods: {
    closeDropdown() {
      this.$emit('close-dropdown');
    },
    trackAndClose({ action, label }) {
      this.trackEvent(action, { label });
      this.closeDropdown();
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
  <gl-disclosure-dropdown-item
    v-else-if="ideItem.href"
    :item="ideItem"
    @action="trackAndClose(ideItem.tracking)"
  >
    <template #list-item>
      <span class="gl-mb-2 gl-flex gl-items-center gl-justify-between">
        <span>{{ ideItem.text }}</span>
        <kbd v-if="ideItem.shortcut && !shortcutsDisabled" class="flat">{{ ideItem.shortcut }}</kbd>
      </span>
    </template>
  </gl-disclosure-dropdown-item>
</template>
