<script>
import { mapGetters } from 'vuex';
import { GlButton, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlIcon,
  },
  computed: {
    ...mapGetters(['dropdownButtonText']),
  },
};
</script>

<template>
  <gl-button class="labels-select-dropdown-button w-100 text-left">
    <span class="dropdown-toggle-text">{{ dropdownButtonText }}</span>
    <gl-icon name="chevron-down" class="pull-right" />
  </gl-button>
</template>
