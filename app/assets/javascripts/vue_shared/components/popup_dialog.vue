<script>
export default {
  name: 'popup-dialog',

  props: {
    title: {
      type: String,
      required: true,
    },
    text: {
      type: String,
      required: false,
    },
    kind: {
      type: String,
      required: false,
      default: 'primary',
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
<div
  class="modal popup-dialog"
  role="dialog"
  tabindex="-1">
  <div class="modal-dialog" role="document">
    <div class="modal-content">
      <div class="modal-header">
        <button type="button"
          class="close"
          @click="close"
          aria-label="Close">
          <span aria-hidden="true">&times;</span>
        </button>
        <h4 class="modal-title">{{this.title}}</h4>
      </div>
      <div class="modal-body">
        <slot name="body" :text="text">
          <p>{{text}}</p>
        </slot>
      </div>
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
    </div>
  </div>
</div>
</template>
