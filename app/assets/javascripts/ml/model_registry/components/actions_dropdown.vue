<script>
import { GlDisclosureDropdown, GlDisclosureDropdownItem, GlModalDirective } from '@gitlab/ui';
import { s__ } from '~/locale';
import { MLFLOW_USAGE_MODAL_ID } from '../constants';
import MlflowUsageModal from './mlflow_usage_modal.vue';

export default {
  components: {
    GlDisclosureDropdownItem,
    GlDisclosureDropdown,
    MlflowUsageModal,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  computed: {
    mlflowUsageModal() {
      return {
        text: s__('MlModelRegistry|Using the MLflow client'),
      };
    },
  },
  modalId: MLFLOW_USAGE_MODAL_ID,
};
</script>

<template>
  <gl-disclosure-dropdown
    placement="bottom-end"
    category="tertiary"
    :aria-label="__('More actions')"
    icon="ellipsis_v"
    no-caret
  >
    <gl-disclosure-dropdown-item v-gl-modal="$options.modalId" :item="mlflowUsageModal" />
    <slot></slot>

    <mlflow-usage-modal />
  </gl-disclosure-dropdown>
</template>
