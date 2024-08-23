<script>
import { GlModal } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { __ } from '~/locale';

export default {
  directives: {
    SafeHtml,
  },
  components: {
    GlModal,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    primaryText: {
      type: String,
      required: false,
      default: __('OK'),
    },
    primaryVariant: {
      type: String,
      required: false,
      default: 'confirm',
    },
    secondaryText: {
      type: String,
      required: false,
      default: '',
    },
    secondaryVariant: {
      type: String,
      required: false,
      default: 'confirm',
    },
    cancelText: {
      type: String,
      required: false,
      default: __('Cancel'),
    },
    cancelVariant: {
      type: String,
      required: false,
      default: 'default',
    },
    modalHtmlMessage: {
      type: String,
      required: false,
      default: '',
    },
    hideCancel: {
      type: Boolean,
      required: false,
      default: false,
    },
    size: {
      type: String,
      required: false,
      default: 'sm',
    },
  },
  computed: {
    primaryAction() {
      return {
        text: this.primaryText,
        attributes: {
          variant: this.primaryVariant,
          'data-testid': 'confirm-ok-button',
        },
      };
    },
    secondaryAction() {
      if (!this.secondaryText) {
        return null;
      }

      return {
        text: this.secondaryText,
        attributes: {
          variant: this.secondaryVariant,
          category: 'secondary',
        },
      };
    },
    cancelAction() {
      return this.hideCancel
        ? null
        : {
            text: this.cancelText,
            attributes: {
              variant: this.cancelVariant,
            },
          };
    },
    shouldShowHeader() {
      return Boolean(this.title?.length);
    },
  },
  mounted() {
    this.$refs.modal.show();
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="confirmationModal"
    body-class="gl-flex"
    data-testid="confirmation-modal"
    :size="size"
    :title="title"
    :action-primary="primaryAction"
    :action-cancel="cancelAction"
    :action-secondary="secondaryAction"
    :hide-header="!shouldShowHeader"
    @primary="$emit('confirmed')"
    @hidden="$emit('closed')"
  >
    <div v-if="!modalHtmlMessage" class="gl-self-center"><slot></slot></div>
    <div v-else v-safe-html="modalHtmlMessage" class="gl-self-center"></div>
  </gl-modal>
</template>
