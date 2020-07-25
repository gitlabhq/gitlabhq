<script>
import { GlFormGroup, GlDeprecatedDropdown, GlDeprecatedDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlFormGroup,
    GlDeprecatedDropdown,
    GlDeprecatedDropdownItem,
  },
  props: {
    name: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      required: false,
      default: '',
    },
    options: {
      type: Object,
      required: true,
    },
  },
  computed: {
    text() {
      const selectedOpt = this.options.values?.find(opt => opt.value === this.value);
      return selectedOpt?.text || this.value;
    },
  },
  methods: {
    onUpdate(value) {
      this.$emit('input', value);
    },
  },
};
</script>
<template>
  <gl-form-group :label="label">
    <gl-deprecated-dropdown
      toggle-class="dropdown-menu-toggle"
      :text="text || s__('Metrics|Select a value')"
    >
      <gl-deprecated-dropdown-item
        v-for="val in options.values"
        :key="val.value"
        @click="onUpdate(val.value)"
        >{{ val.text }}</gl-deprecated-dropdown-item
      >
    </gl-deprecated-dropdown>
  </gl-form-group>
</template>
