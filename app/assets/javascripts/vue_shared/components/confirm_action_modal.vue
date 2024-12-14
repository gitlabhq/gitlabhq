<script>
/**
 * This component is a modal where when the OK button is clicked, rather than closing immediately, it will await the
 * function passed in as the actionFn prop, show the modal as loading, and prevent the user from closing it until the
 * function is done. It is intended to be used for actions that perform a network request but requires confirmation, for
 * example deleting an item.
 *
 * Usage example:
 *   async function removeItem() {
 *     const response = await doNetworkRequest();
 *     if (response.errorMessage) {
 *       return Promise.reject(response.errorMessage);
 *     }
 *
 *     return Promise.resolve().then(handleSuccess);
 *   }
 *
 *   <confirm-action-modal
 *     v-if="itemToRemove"
 *     title="Remove item?"
 *     :action-fn="removeItem"
 *     action-text="Remove"
 *     variant="danger"
 *     @close="itemToRemove = null"
 *    >
 *      Do you really want to remove this item?
 *      <template #error="{ message }">
 *        This template is optional, the error message will be shown in a GlAlert if not provided.
 *        {{ message }}
 *      </template>
 *   </confirm-action-modal>
 *
 * Props:
 *   title - modal header text
 *   actionText - text for the OK button
 *   cancelText - text for the Cancel button (default: 'Cancel')
 *   variant - variant for the OK button (default: 'confirm')
 *   actionFn - function to run when the OK button is clicked. The function should return a promise. If the promise is
 *              rejected, the rejected value should be the error message.
 *
 * Slots:
 *   default - the modal body content
 *   error - the custom error if provided, and only shown if there is an error. It will show below the modal body
 *           content. If not provided, a GlAlert will show the error message.
 *
 * Notes:
 *   The modal will close automatically after the actionFn is done running. There is currently no support to keep the
 *   modal open after the action completes. When the modal closes, it will first play a slide out animation, then emit
 *   the @close event after the animation is done. If you need to refresh data, you may want to do it immediately after
 *   the actionFn is complete rather than wait for the slide out animation. Also, if you want to skip the slide out
 *   animation, simply un-render the modal. Example:
 *
 *   deleteItem() {
 *     await doDeleteRequest();
 *     this.refreshData(); // Refreshes the data immediately.
 *     this.isModalVisible = false; // Close the modal immediately.
 *   }
 */
import { GlModal, GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: { GlModal, GlAlert },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
    actionText: {
      type: String,
      required: true,
    },
    cancelText: {
      type: String,
      required: false,
      default: __('Cancel'),
    },
    variant: {
      type: String,
      required: false,
      default: 'danger',
    },
    actionFn: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
      errorMessage: '',
    };
  },
  computed: {
    primaryActionProps() {
      return {
        text: this.actionText,
        attributes: { variant: this.variant, loading: this.loading },
      };
    },
    cancelActionProps() {
      return {
        text: this.cancelText,
        attributes: { disabled: this.loading },
      };
    },
  },
  methods: {
    async performAction() {
      try {
        this.loading = true;
        this.errorMessage = '';

        await this.actionFn();

        this.$refs.modal.hide();
      } catch (error) {
        // error can be either an Error object from an exception or from Promise.reject() with an
        // error message.
        this.errorMessage = error?.message || error;
        this.loading = false;
      }
    },
    checkModalClose(e) {
      // If the modal is closing from user interaction but the action is running, don't close it.
      // We'll allow it to close if the action is not running or if modal.hide() was called.
      if (e.trigger && this.loading) {
        e.preventDefault();
      }
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    :modal-id="modalId"
    visible
    no-focus-on-show
    :title="title"
    :action-primary="primaryActionProps"
    :action-cancel="cancelActionProps"
    size="sm"
    @primary.prevent="performAction"
    @hide="checkModalClose"
    @hidden="$emit('close')"
  >
    <slot></slot>

    <slot v-if="errorMessage" name="error" :message="errorMessage">
      <gl-alert variant="danger" :dismissible="false" class="gl-mt-4">
        {{ errorMessage }}
      </gl-alert>
    </slot>
  </gl-modal>
</template>
