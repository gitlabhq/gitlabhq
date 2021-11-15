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
  methods: {
    onClickAction(action) {
      if (action.onClick) {
        action.onClick();
      }
    },
  },
};
</script>

<template>
  <div>
    <gl-dropdown
      v-if="tertiaryButtons.length"
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
        @click="onClickAction(btn)"
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
        :class="{ 'gl-mr-3': index !== tertiaryButtons.length - 1 }"
        category="tertiary"
        variant="confirm"
        size="small"
        class="gl-display-none gl-md-display-block gl-float-left"
        @click="onClickAction(btn)"
      >
        {{ btn.text }}
      </gl-button>
    </template>
  </div>
</template>
