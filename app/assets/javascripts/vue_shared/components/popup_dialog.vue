<script>
export default {
  name: 'popup-dialog',

  props: {
    title: {
      type: String,
      required: false,
    },
    body: {
      type: String,
      required: false,
    },
    kind: {
      type: String,
      required: false,
      default: 'primary',
    },
    closeButtonLabel: {
      type: String,
      required: false,
      default: 'Cancel',
    },
    primaryButtonLabel: {
      type: String,
      required: false,
    },
  },

  computed: {
    btnKindClass() {
      return {
        [`btn-${this.kind}`]: true,
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
        <slot name="header">
          <button type="button"
            class="close"
            @click="close"
            aria-label="Close">
            <span aria-hidden="true">&times;</span>
          </button>
          <h4 class="modal-title">{{this.title}}</h4>
        </slot>
      </div>
      <div class="modal-body">
        <slot>
          <p>{{this.body}}</p>
        </slot>
      </div>
      <div class="modal-footer">
        <slot name="footer">
          <button
            type="button"
            class="btn btn-default"
            @click="emitSubmit(false)">
              {{closeButtonLabel}}
          </button>
          <button type="button"
            class="btn"
            :class="btnKindClass"
            @click="emitSubmit(true)">
              {{primaryButtonLabel}}
          </button>
        </slot>
      </div>
    </div>
  </div>
</div>
</template>
