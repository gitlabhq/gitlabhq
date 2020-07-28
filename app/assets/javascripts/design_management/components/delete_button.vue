<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__ } from '~/locale';

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
  },
  data() {
    return {
      modalId: uniqueId('design-deletion-confirmation-'),
    };
  },
  modal: {
    title: s__('DesignManagement|Delete designs confirmation'),
    actionPrimary: {
      text: s__('Delete'),
      attributes: { variant: 'danger' },
    },
    actionCancel: {
      text: s__('Cancel'),
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-center gl-h-full">
    <gl-modal
      :modal-id="modalId"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @ok="$emit('deleteSelectedDesigns')"
    >
      <p>{{ s__('DesignManagement|Are you sure you want to delete the selected designs?') }}</p>
    </gl-modal>
    <gl-button
      v-gl-modal-directive="modalId"
      :variant="buttonVariant"
      :size="buttonSize"
      :class="buttonClass"
      :disabled="isDeleting || !hasSelectedDesigns"
    >
      <slot></slot>
    </gl-button>
  </div>
</template>
