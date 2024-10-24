<script>
import {
  GlModal,
  GlTooltipDirective,
  GlDisclosureDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';

export default {
  components: {
    GlModal,
    GlDisclosureDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlModalDirective,
  },
  data() {
    return {
      isDeleteModalVisible: false,
      modal: {
        id: 'ml-experiments-delete-modal',
        deleteConfirmation: this.deleteConfirmationText,
        actionPrimary: {
          text: this.$options.i18n.actionPrimaryText,
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
  i18n: {
    actionPrimaryText: s__('MlModelRegistry|Delete model'),
    modalTitle: s__('MlModelRegistry|Delete model'),
    deleteConfirmationText: s__(
      'MlExperimentTracking|Are you sure you would like to delete this model?',
    ),
    deleteConfirmationNote: s__(
      'MlExperimentTracking|Deleting this model also deletes all its versions, including any imported or uploaded artifacts, and their associated settings.',
    ),
  },
};
</script>

<template>
  <gl-disclosure-dropdown-item
    v-gl-modal-directive="modal.id"
    :aria-label="$options.i18n.actionPrimaryText"
    variant="danger"
  >
    <template #list-item>
      <span class="gl-text-red-500">
        {{ $options.i18n.actionPrimaryText }}
      </span>

      <gl-modal
        :modal-id="modal.id"
        :title="$options.i18n.modalTitle"
        :action-primary="modal.actionPrimary"
        :action-cancel="modal.actionCancel"
        @primary="confirmDelete"
      >
        <p>
          {{ $options.i18n.deleteConfirmationText }}
        </p>
        <p data-testid="confirmation-note">
          <b>{{ __('Note:') }}</b>
          {{ $options.i18n.deleteConfirmationNote }}
        </p>
      </gl-modal>
    </template>
  </gl-disclosure-dropdown-item>
</template>
