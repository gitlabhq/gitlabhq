<script>
import { mapActions, mapGetters } from 'vuex';
import { GlButton, GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlIcon,
  },
  computed: {
    ...mapGetters(['dropdownButtonText', 'isDropdownVariantStandalone']),
  },
  methods: {
    ...mapActions(['toggleDropdownContents']),
    handleButtonClick(e) {
      if (this.isDropdownVariantStandalone) {
        this.toggleDropdownContents();
        e.stopPropagation();
      }
    },
  },
};
</script>

<template>
  <gl-button
    class="labels-select-dropdown-button js-dropdown-button w-100 text-left"
    @click="handleButtonClick"
  >
    <span class="dropdown-toggle-text flex-fill">
      {{ dropdownButtonText }}
    </span>
    <gl-icon name="chevron-down" class="pull-right" />
  </gl-button>
</template>
