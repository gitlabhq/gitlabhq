<script>
import { GlButton } from '@gitlab/ui';

export default {
  components: {
    GlButton,
  },
  props: {
    dropdownTitle: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <div class="dropdown-title gl-flex gl-items-center !gl-pb-3 gl-pt-0">
      <span class="gl-grow">{{ dropdownTitle }}</span>
      <gl-button
        :aria-label="__('Close')"
        variant="link"
        size="small"
        class="dropdown-header-button !gl-p-0"
        icon="close"
        @click="$emit('closeDropdown')"
      />
    </div>
  </div>
</template>
