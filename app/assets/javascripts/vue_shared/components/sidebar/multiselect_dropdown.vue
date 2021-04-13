<script>
import { GlDropdown, GlDropdownForm, GlDropdownDivider } from '@gitlab/ui';

export default {
  components: {
    GlDropdownForm,
    GlDropdown,
    GlDropdownDivider,
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
  <gl-dropdown class="show" :text="text" @toggle="$emit('toggle')">
    <template #header>
      <p class="gl-font-weight-bold gl-text-center gl-mt-2 gl-mb-4">{{ headerText }}</p>
      <gl-dropdown-divider />
      <slot name="search"></slot>
    </template>
    <gl-dropdown-form>
      <slot name="items"></slot>
    </gl-dropdown-form>
    <template #footer>
      <slot name="footer"></slot>
    </template>
  </gl-dropdown>
</template>
