<script>
import {
  GlModal,
  GlDropdown,
  GlTooltipDirective,
  GlDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import csrf from '~/lib/utils/csrf';

export default {
  components: {
    GlModal,
    GlDropdown,
    GlDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  props: {
    deletePath: {
      type: String,
      required: true,
    },
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
      this.$refs.deleteForm.submit();
    },
  },
  csrf,
};
</script>

<template>
  <gl-dropdown
    right
    category="tertiary"
    :aria-label="__('More actions')"
    icon="ellipsis_v"
    no-caret
  >
    <gl-dropdown-item
      v-gl-modal-directive="modal.id"
      :aria-label="actionPrimaryText"
      variant="danger"
    >
      {{ actionPrimaryText }}

      <form ref="deleteForm" method="post" :action="deletePath">
        <input type="hidden" name="_method" value="delete" />
        <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
      </form>

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
    </gl-dropdown-item>
  </gl-dropdown>
</template>
