<script>
  import ModalButton from './modal_button.vue';

  export default {
    name: 'GlModal',

    components: {
      ModalButton,
    },

    props: {
      id: {
        type: String,
        required: false,
        default: null,
      },
      headerTitleText: {
        type: String,
        required: false,
        default: '',
      },
      footerPrimaryButtonVariant: {
        type: String,
        required: false,
        default: 'primary',
      },
      footerPrimaryButtonText: {
        type: String,
        required: false,
        default: '',
      },
      footerSecondaryButtonVariant: {
        type: String,
        required: false,
        default: 'default',
      },
      footerSecondaryButtonText: {
        type: String,
        required: false,
        default: '',
      },
    },

    computed: {
      hasSecondaryButton() {
        return this.footerSecondaryButtonText && this.footerSecondaryButtonText !== '';
      },
    },

    methods: {
      emitCancel(event) {
        this.$emit('cancel', event);
      },
      emitSecondaryAction(event) {
        this.$emit('secondaryAction', event);
      },
      emitSubmit(event) {
        this.$emit('submit', event);
      },
    },
  };
</script>

<template>
  <div
    :id="id"
    class="modal fade"
    tabindex="-1"
    role="dialog"
  >
    <div
      class="modal-dialog"
      role="document"
    >
      <div class="modal-content">
        <div class="modal-header">
          <slot name="header">
            <button
              type="button"
              class="close"
              data-dismiss="modal"
              :aria-label="s__('Modal|Close')"
              @click="emitCancel($event)"
            >
              <span aria-hidden="true">&times;</span>
            </button>
            <h4 class="modal-title">
              <slot name="title">
                {{ headerTitleText }}
              </slot>
            </h4>
          </slot>
        </div>

        <div class="modal-body">
          <slot></slot>
        </div>

        <div class="modal-footer">
          <slot name="footer">
            <modal-button @click="emitCancel($event)">
              {{ s__('Modal|Cancel') }}
            </modal-button>
            <modal-button
              v-if="hasSecondaryButton"
              :variant="footerSecondaryButtonVariant"
              @click="emitSecondaryAction($event)"
            >
              {{ footerSecondaryButtonText }}
            </modal-button>
            <modal-button
              :variant="footerPrimaryButtonVariant"
              @click="emitSubmit($event)"
            >
              {{ footerPrimaryButtonText }}
            </modal-button>
          </slot>
        </div>
      </div>
    </div>
  </div>
</template>
