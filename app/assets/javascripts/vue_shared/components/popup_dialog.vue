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
  tabindex="-1"
>
  <div
    class="modal-dialog modal-lg"
    role="document"
  >
    <div class="modal-content">
      <div class="modal-header">
        <slot name="header">
          <h4 class="modal-title pull-left">{{this.title}}</h4>
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
        <slot>
          <p>{{this.body}}</p>
        </slot>
      </div>
      <slot name="footer">
        <div class="modal-footer">
          <button type="button"
            class="btn pull-left"
            :class="btnKindClass"
            @click="emitSubmit(true)">
              {{primaryButtonLabel}}
          </button>
          <button
            type="button"
            class="btn btn-default pull-right"
            @click="close">
              Cancel
          </button>
        </div>
      </slot>
    </div>
  </div>
</div>
</template>
