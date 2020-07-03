<script>
import { GlFormGroup, GlDropdown, GlDropdownItem } from '@gitlab/ui';

export default {
  components: {
    GlFormGroup,
    GlDropdown,
    GlDropdownItem,
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
    <gl-dropdown toggle-class="dropdown-menu-toggle" :text="text || s__('Metrics|Select a value')">
      <gl-dropdown-item
        v-for="val in options.values"
        :key="val.value"
        @click="onUpdate(val.value)"
        >{{ val.text }}</gl-dropdown-item
      >
    </gl-dropdown>
  </gl-form-group>
</template>
