<script>
import { GlButton, GlIcon } from '@gitlab/ui';
import { mapActions, mapGetters } from 'vuex';

export default {
  components: {
    GlButton,
    GlIcon,
  },
  computed: {
    ...mapGetters([
      'dropdownButtonText',
      'isDropdownVariantStandalone',
      'isDropdownVariantEmbedded',
    ]),
  },
  methods: {
    ...mapActions(['toggleDropdownContents']),
    handleButtonClick(e) {
      if (this.isDropdownVariantStandalone || this.isDropdownVariantEmbedded) {
        this.toggleDropdownContents();
      }

      if (this.isDropdownVariantStandalone) {
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
    <span class="dropdown-toggle-text gl-pointer-events-none flex-fill">
      {{ dropdownButtonText }}
    </span>
    <gl-icon name="chevron-down" class="gl-pointer-events-none float-right" />
  </gl-button>
</template>
