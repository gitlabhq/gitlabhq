<script>
import { GlButton, GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    widget: {
      type: String,
      required: true,
    },
    tertiaryButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    dropdownLabel() {
      return sprintf(__('%{widget} options'), { widget: this.widget });
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown
      v-if="tertiaryButtons"
      :text="dropdownLabel"
      icon="ellipsis_v"
      no-caret
      category="tertiary"
      right
      lazy
      text-sr-only
      size="small"
      toggle-class="gl-p-2!"
      class="gl-display-block gl-md-display-none!"
    >
      <gl-dropdown-item
        v-for="(btn, index) in tertiaryButtons"
        :key="index"
        :href="btn.href"
        :target="btn.target"
      >
        {{ btn.text }}
      </gl-dropdown-item>
    </gl-dropdown>
    <template v-if="tertiaryButtons.length">
      <gl-button
        v-for="(btn, index) in tertiaryButtons"
        :key="index"
        :href="btn.href"
        :target="btn.target"
        :class="{ 'gl-mr-3': index > 1 }"
        category="tertiary"
        variant="confirm"
        size="small"
        class="gl-display-none gl-md-display-block"
      >
        {{ btn.text }}
      </gl-button>
    </template>
  </div>
</template>
