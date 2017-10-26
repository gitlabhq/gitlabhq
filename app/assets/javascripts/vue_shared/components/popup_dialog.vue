<script>
export default {
  name: 'popup-dialog',

  props: {
    title: {
      type: String,
      required: false,
    },
    text: {
      type: String,
      required: false,
<<<<<<< HEAD
=======
    },
    hideFooter: {
      type: Boolean,
      required: false,
      default: false,
>>>>>>> e8a46294c0... apply changes for JS and CSS from gitlab-ee!2912
    },
    kind: {
      type: String,
      required: false,
      default: 'primary',
    },
    modalDialogClass: {
      type: String,
      required: false,
      default: '',
    },
    closeKind: {
      type: String,
      required: false,
      default: 'default',
    },
    closeButtonLabel: {
      type: String,
      required: false,
      default: 'Cancel',
    },
    primaryButtonLabel: {
      type: String,
      required: true,
    },
    submitDisabled: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  computed: {
    btnKindClass() {
      return {
        [`btn-${this.kind}`]: true,
      };
    },
    btnCancelKindClass() {
      return {
        [`btn-${this.closeKind}`]: true,
      };
    },
  },

  methods: {
    close() {
      this.$emit('toggle', false);
    },
    emitSubmit(status) {
      this.$emit('submit', status);
    },
  },
};
</script>

<template>
<div class="modal-open">
  <div
    class="modal popup-dialog"
    role="dialog"
    tabindex="-1"
  >
    <div
      :class="modalDialogClass"
      class="modal-dialog"
      role="document"
    >
      <div class="modal-content">
        <div class="modal-header">
          <slot name="header">
            <h4 class="modal-title pull-left">
              {{this.title}}
            </h4>
            <button
              type="button"
              class="close pull-right"
              @click="close"
              aria-label="Close"
            >
              <span aria-hidden="true">&times;</span>
            </button>
          </slot>
        </div>
        <div class="modal-body">
          <slot name="body" :text="text">
            <p>{{this.text}}</p>
          </slot>
        </div>
        <slot name="footer">
          <div class="modal-footer" v-if="!hideFooter">
            <button
              type="button"
              class="btn btn-default pull-left"
              @click="close"
            >
              Cancel
            </button>
            <button
              type="button"
              class="btn pull-right"
              :disabled="submitDisabled"
              :class="btnKindClass"
              @click="emitSubmit(true)"
            >
              {{primaryButtonLabel}}
            </button>
          </div>
        </slot>
      </div>
<<<<<<< HEAD
      <div class="modal-footer">
        <button
          type="button"
          class="btn"
          :class="btnCancelKindClass"
          @click="close">
          {{ closeButtonLabel }}
        </button>
        <button
          type="button"
          class="btn"
          :class="btnKindClass"
          @click="emitSubmit(true)">
          {{ primaryButtonLabel }}
        </button>
      </div>
=======
>>>>>>> e8a46294c0... apply changes for JS and CSS from gitlab-ee!2912
    </div>
  </div>
  <div class="modal-backdrop fade in" />
</div>
</template>
