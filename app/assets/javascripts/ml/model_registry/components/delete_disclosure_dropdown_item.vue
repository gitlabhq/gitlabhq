<script>
import {
  GlModal,
  GlTooltipDirective,
  GlDisclosureDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlModal,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  props: {
    deleteConfirmationText: {
      type: String,
      required: true,
    },
    actionPrimaryText: {
      type: String,
      required: true,
    },
    modalTitle: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isDeleteModalVisible: false,
      modal: {
        id: 'ml-experiments-delete-modal',
        deleteConfirmation: this.deleteConfirmationText,
        actionPrimary: {
          text: this.actionPrimaryText,
          attributes: { variant: 'danger' },
        },
        actionCancel: {
          text: __('Cancel'),
        },
      },
    };
  },
  methods: {
    confirmDelete() {
      this.$emit('confirm-deletion');
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item
    v-gl-modal-directive="modal.id"
    :aria-label="actionPrimaryText"
    variant="danger"
  >
    <template #list-item>
      <span class="gl-text-red-500">
        {{ actionPrimaryText }}
      </span>

      <gl-modal
        :modal-id="modal.id"
        :title="modalTitle"
        :action-primary="modal.actionPrimary"
        :action-cancel="modal.actionCancel"
        @primary="confirmDelete"
      >
        <p>
          {{ deleteConfirmationText }}
        </p>
      </gl-modal>
    </template>
  </gl-disclosure-dropdown-item>
</template>
