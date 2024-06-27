<script>
import { GlDisclosureDropdown } from '@gitlab/ui';

export default {
  components: {
    GlDisclosureDropdown,
  },
  props: {
    actions: {
      type: Array,
      required: true,
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    :toggle-text="__('Add')"
    size="small"
    placement="bottom-end"
    :items="actions"
  />
</template>
