<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__, __ } from '~/locale';

export default {
  name: 'DeleteButton',
  components: {
    GlButton,
    GlModal,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    isDeleting: {
      type: Boolean,
      required: false,
      default: false,
    },
    buttonClass: {
      type: String,
      required: false,
      default: '',
    },
    buttonVariant: {
      type: String,
      required: false,
      default: 'info',
    },
    buttonCategory: {
      type: String,
      required: false,
      default: 'primary',
    },
    buttonIcon: {
      type: String,
      required: false,
      default: undefined,
    },
    buttonSize: {
      type: String,
      required: false,
      default: 'medium',
    },
    hasSelectedDesigns: {
      type: Boolean,
      required: false,
      default: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      modalId: uniqueId('design-deletion-confirmation-'),
    };
  },
  modal: {
    title: s__('DesignManagement|Are you sure you want to archive the selected designs?'),
    actionPrimary: {
      text: s__('DesignManagement|Archive designs'),
      attributes: { variant: 'confirm', 'data-qa-selector': 'confirm_archiving_button' },
    },
    actionCancel: {
      text: __('Cancel'),
    },
  },
};
</script>

<template>
  <div>
    <gl-modal
      :modal-id="modalId"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @ok="$emit('delete-selected-designs')"
    >
      {{
        s__(
          'DesignManagement|Archived designs will still be available in previous versions of the design collection.',
        )
      }}
    </gl-modal>
    <gl-button
      v-gl-modal-directive="modalId"
      :variant="buttonVariant"
      :category="buttonCategory"
      :size="buttonSize"
      :class="buttonClass"
      :loading="loading"
      :icon="buttonIcon"
      :disabled="isDeleting || !hasSelectedDesigns"
      ><slot></slot
    ></gl-button>
  </div>
</template>
