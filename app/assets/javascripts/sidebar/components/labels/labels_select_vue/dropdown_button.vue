<script>
import { GlButton, GlIcon } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters } from 'vuex';

// @deprecated This component should only be used when there is no GraphQL API.
// In most cases you should use
// `app/assets/javascripts/sidebar/components/labels/labels_select_widget` instead.
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
    class="labels-select-dropdown-button js-dropdown-button text-left gl-w-full"
    @click="handleButtonClick"
  >
    <span class="dropdown-toggle-text flex-fill gl-pointer-events-none">
      {{ dropdownButtonText }}
    </span>
    <gl-icon name="chevron-down" class="gl-pointer-events-none gl-float-right" />
  </gl-button>
</template>
