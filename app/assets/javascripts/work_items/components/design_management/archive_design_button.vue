<script>
import { GlButton, GlModal, GlModalDirective } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { s__, __ } from '~/locale';

export default {
  name: 'ArchiveDesignButton',
  components: {
    GlButton,
    GlModal,
  },
  directives: {
    GlModalDirective,
  },
  props: {
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
    buttonIcon: {
      type: String,
      required: false,
      default: undefined,
    },
    buttonCategory: {
      type: String,
      required: false,
      default: 'primary',
    },
    buttonClass: {
      type: String,
      required: false,
      default: '',
    },
    buttonSize: {
      type: String,
      required: false,
      default: 'small',
    },
  },
  data() {
    return {
      modalId: uniqueId('design-archive-confirmation-'),
    };
  },
  modal: {
    title: s__('DesignManagement|Are you sure you want to archive the selected designs?'),
    text: s__(
      'DesignManagement|Archived designs will still be available in previous versions of the design collection.',
    ),
    actionPrimary: {
      text: s__('DesignManagement|Archive designs'),
      attributes: { variant: 'confirm', 'data-testid': 'confirm-archiving-button' },
    },
    actionCancel: {
      text: __('Cancel'),
    },
  },
};
</script>

<template>
  <div :class="buttonClass">
    <gl-modal
      :modal-id="modalId"
      :title="$options.modal.title"
      :action-primary="$options.modal.actionPrimary"
      :action-cancel="$options.modal.actionCancel"
      @ok="$emit('archive-selected-designs')"
    >
      {{ $options.modal.text }}
    </gl-modal>
    <gl-button
      v-gl-modal-directive="modalId"
      data-testid="archive-design-button"
      :size="buttonSize"
      :category="buttonCategory"
      :icon="buttonIcon"
      :loading="loading"
      :class="buttonClass"
      :disabled="!hasSelectedDesigns || loading"
    >
      <slot></slot>
    </gl-button>
  </div>
</template>
