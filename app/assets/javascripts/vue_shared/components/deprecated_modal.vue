<script>
  /* eslint-disable vue/require-default-prop */
  export default {
    name: 'DeprecatedModal', // use GlModal instead

    props: {
      id: {
        type: String,
        required: false,
      },
      title: {
        type: String,
        required: false,
      },
      text: {
        type: String,
        required: false,
      },
      hideFooter: {
        type: Boolean,
        required: false,
        default: false,
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
        required: false,
        default: '',
      },
      secondaryButtonLabel: {
        type: String,
        required: false,
        default: '',
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
      emitCancel(event) {
        this.$emit('cancel', event);
      },
      emitSubmit(event) {
        this.$emit('submit', event);
      },
    },
  };
</script>

<template>
  <div class="modal-open">
    <div
      :id="id"
      class="modal"
      :class="id ? '' : 'show'"
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
                {{ title }}
              </h4>
              <button
                type="button"
                class="close pull-right"
                @click="emitCancel($event)"
                data-dismiss="modal"
                aria-label="Close"
              >
                <span aria-hidden="true">&times;</span>
              </button>
            </slot>
          </div>
          <div class="modal-body">
            <slot
              name="body"
              :text="text"
            >
              <p>{{ text }}</p>
            </slot>
          </div>
          <div
            class="modal-footer"
            v-if="!hideFooter"
          >
            <button
              type="button"
              class="btn"
              :class="btnCancelKindClass"
              @click="emitCancel($event)"
              data-dismiss="modal"
            >
              {{ closeButtonLabel }}
            </button>

            <slot
              v-if="secondaryButtonLabel"
              name="secondary-button"
            >
              <button
                v-if="secondaryButtonLabel"
                type="button"
                class="btn"
                data-dismiss="modal"
              >
                {{ secondaryButtonLabel }}
              </button>
            </slot>

            <button
              v-if="primaryButtonLabel"
              type="button"
              class="btn js-primary-button"
              :disabled="submitDisabled"
              :class="btnKindClass"
              @click="emitSubmit($event)"
              data-dismiss="modal"
            >
              {{ primaryButtonLabel }}
            </button>
          </div>
        </div>
      </div>
    </div>
    <div
      v-if="!id"
      class="modal-backdrop fade in"
    >
    </div>
  </div>
</template>
