<script>
import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import {
  INCIDENTS_I18N as i18n,
  STATUS_ACKNOWLEDGED,
  STATUS_TRIGGERED,
  STATUS_RESOLVED,
} from '../../constants';
import { getStatusLabel } from '../../utils';

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
    preventDropdownClose: {
      type: Boolean,
      required: false,
      default: false,
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
    hideDropdown(event) {
      if (this.preventDropdownClose) {
        event.preventDefault();
      }
    },
  },
};
</script>

<template>
  <gl-dropdown
    ref="dropdown"
    block
    :text="currentStatusLabel"
    toggle-class="dropdown-menu-toggle gl-mb-2"
    @hide="hideDropdown"
  >
    <slot name="header"> </slot>
    <gl-dropdown-item
      v-for="status in $options.STATUS_LIST"
      :key="status"
      data-testid="status-dropdown-item"
      is-check-item
      :is-checked="status === value"
      @click="$emit('input', status)"
    >
      {{ getStatusLabel(status) }}
    </gl-dropdown-item>
  </gl-dropdown>
</template>
