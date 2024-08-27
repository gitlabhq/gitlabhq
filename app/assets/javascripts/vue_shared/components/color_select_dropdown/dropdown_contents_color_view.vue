<script>
import { GlDropdownForm, GlDropdownItem } from '@gitlab/ui';
import ColorItem from './color_item.vue';
import { ISSUABLE_COLORS } from './constants';

export default {
  components: {
    GlDropdownForm,
    GlDropdownItem,
    ColorItem,
  },
  model: {
    prop: 'selectedColor',
  },
  props: {
    selectedColor: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      colors: ISSUABLE_COLORS,
    };
  },
  methods: {
    isColorSelected(color) {
      return this.selectedColor.color === color.color;
    },
    handleColorClick(color) {
      this.$emit('input', color);
      this.$emit('closeDropdown', this.selectedColor);
    },
  },
};
</script>

<template>
  <gl-dropdown-form class="js-colors-list">
    <div data-testid="dropdown-content">
      <gl-dropdown-item
        v-for="color in colors"
        :key="color.color"
        :is-checked="isColorSelected(color)"
        is-check-centered
        is-check-item
        @click.capture.native.stop="handleColorClick(color)"
      >
        <color-item :color="color.color" :title="color.title" />
      </gl-dropdown-item>
    </div>
  </gl-dropdown-form>
</template>
