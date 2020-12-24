<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    visibilityLevelOptions: {
      type: Array,
      required: true,
    },
    defaultLevel: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      selectedOption: this.getDefaultOption(),
    };
  },
  methods: {
    getDefaultOption() {
      return this.visibilityLevelOptions.find((option) => option.level === this.defaultLevel);
    },
    onClick(option) {
      this.selectedOption = option;
    },
  },
};
</script>
<template>
  <div>
    <input type="hidden" name="group[visibility_level]" :value="selectedOption.level" />
    <gl-dropdown :text="selectedOption.label" class="gl-w-full" menu-class="gl-w-full! gl-mb-0">
      <gl-dropdown-item
        v-for="option in visibilityLevelOptions"
        :key="option.level"
        :secondary-text="option.description"
        @click="onClick(option)"
      >
        <div class="gl-font-weight-bold gl-mb-1">{{ option.label }}</div>
      </gl-dropdown-item>
    </gl-dropdown>
  </div>
</template>
