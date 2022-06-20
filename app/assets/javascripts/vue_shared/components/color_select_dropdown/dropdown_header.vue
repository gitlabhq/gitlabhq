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
    <div class="dropdown-title gl-display-flex gl-align-items-center gl-pt-0 gl-pb-3!">
      <span class="gl-flex-grow-1">{{ dropdownTitle }}</span>
      <gl-button
        :aria-label="__('Close')"
        variant="link"
        size="small"
        class="dropdown-header-button gl-p-0!"
        icon="close"
        @click="$emit('closeDropdown')"
      />
    </div>
  </div>
</template>
