<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
  },
  inject: ['mlflowTrackingUrl'],
  computed: {
    copyIdItem() {
      return {
        text: s__('MlModelRegistry|Copy MLflow tracking URL'),
        action: () => {
          this.$toast.show(s__('MlModelRegistry|Copied MLflow tracking URL to clipboard'));
        },
      };
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    placement="right"
    category="tertiary"
    :aria-label="__('More actions')"
    icon="ellipsis_v"
    no-caret
  >
    <gl-disclosure-dropdown-item :item="copyIdItem" :data-clipboard-text="mlflowTrackingUrl" />
    <slot></slot>
  </gl-disclosure-dropdown>
</template>
