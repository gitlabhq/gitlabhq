<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { i18n, STATUS_ACKNOWLEDGED, STATUS_TRIGGERED, STATUS_RESOLVED } from './constants';
import { getStatusLabel } from './utils';

const STATUS_LIST = [STATUS_TRIGGERED, STATUS_ACKNOWLEDGED, STATUS_RESOLVED];

export default {
  i18n,
  STATUS_LIST,
  components: {
    GlDropdown,
    GlDropdownItem,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: null,
      validator(value) {
        return [...STATUS_LIST, null].includes(value);
      },
    },
  },
  computed: {
    currentStatusLabel() {
      return this.getStatusLabel(this.value);
    },
  },
  methods: {
    show() {
      this.$refs.dropdown.show();
    },
    hide() {
      this.$refs.dropdown.hide();
    },
    getStatusLabel,
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    block
    :text="currentStatusLabel"
    toggle-class="dropdown-menu-toggle gl-mb-2"
  >
    <slot name="header"> </slot>
    <gl-dropdown-item
      v-for="status in $options.STATUS_LIST"
      :key="status"
      data-testid="status-dropdown-item"
      :is-check-item="true"
      :is-checked="status === value"
      @click="$emit('input', status)"
    >
      {{ getStatusLabel(status) }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
