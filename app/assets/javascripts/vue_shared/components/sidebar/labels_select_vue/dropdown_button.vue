<script>
import { mapGetters } from 'vuex';
import { GlDeprecatedButton, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlDeprecatedButton,
    GlIcon,
  },
  computed: {
    ...mapGetters(['dropdownButtonText']),
  },
};
</script>

<template>
  <gl-deprecated-button class="labels-select-dropdown-button w-100 text-left">
    <span class="dropdown-toggle-text">{{ dropdownButtonText }}</span>
    <gl-icon name="chevron-down" class="pull-right" />
  </gl-deprecated-button>
</template>
