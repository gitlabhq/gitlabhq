<script>
import { GlDropdown, GlDropdownForm } from '@gitlab/ui';

export default {
  components: {
    GlDropdownForm,
    GlDropdown,
  },
  props: {
    headerText: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-dropdown class="show" :text="text" :header-text="headerText">
    <gl-dropdown-form>
      <slot name="items"></slot>
    </gl-dropdown-form>
  </gl-dropdown>
</template>
