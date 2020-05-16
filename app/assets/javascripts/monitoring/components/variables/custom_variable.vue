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
      type: Array,
      required: true,
    },
  },
  computed: {
    defaultText() {
      const selectedOpt = this.options.find(opt => opt.value === this.value);
      return selectedOpt?.text || this.value;
    },
  },
  methods: {
    onUpdate(value) {
      this.$emit('onUpdate', this.name, value);
    },
  },
};
</script>
<template>
  <gl-form-group :label="label">
    <gl-dropdown toggle-class="dropdown-menu-toggle" :text="defaultText">
      <gl-dropdown-item v-for="(opt, key) in options" :key="key" @click="onUpdate(opt.value)">{{
        opt.text
      }}</gl-dropdown-item>
    </gl-dropdown>
  </gl-form-group>
</template>
