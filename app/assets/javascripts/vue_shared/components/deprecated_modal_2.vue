<script>
import $ from 'jquery';
import { GlButton } from '@gitlab/ui';

const buttonVariants = ['danger', 'primary', 'success', 'warning'];
const sizeVariants = ['sm', 'md', 'lg', 'xl'];

export default {
  name: 'DeprecatedModal2', // use GlModal instead

  components: {
    GlButton,
  },
  props: {
    id: {
      type: String,
      required: false,
      default: null,
    },
    modalSize: {
      type: String,
      required: false,
      default: 'md',
      validator: value => sizeVariants.includes(value),
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
      validator: value => buttonVariants.includes(value),
    },
    footerPrimaryButtonText: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    modalSizeClass() {
      return this.modalSize === 'md' ? '' : `modal-${this.modalSize}`;
    },
  },
  mounted() {
    $(this.$el)
      .on('shown.bs.modal', this.opened)
      .on('hidden.bs.modal', this.closed);
  },
  beforeDestroy() {
    $(this.$el)
      .off('shown.bs.modal', this.opened)
      .off('hidden.bs.modal', this.closed);
  },
  methods: {
    emitCancel(event) {
      this.$emit('cancel', event);
    },
    emitSubmit(event) {
      this.$emit('submit', event);
    },
    opened() {
      this.$emit('open');
    },
    closed() {
      this.$emit('closed');
    },
  },
};
</script>

<template>
  <div :id="id" class="modal fade" tabindex="-1" role="dialog">
    <div :class="modalSizeClass" class="modal-dialog" role="document">
      <div class="modal-content">
        <div class="modal-header gl-pr-4">
          <slot name="header">
            <h4 class="modal-title">
              <slot name="title"> {{ headerTitleText }} </slot>
            </h4>
            <gl-button
              :aria-label="s__('Modal|Close')"
              variant="default"
              category="tertiary"
              size="small"
              icon="close"
              class="js-modal-close-action"
              data-dismiss="modal"
              @click="emitCancel($event)"
            />
          </slot>
        </div>

        <div class="modal-body"><slot></slot></div>

        <div class="modal-footer">
          <slot name="footer">
            <gl-button
              class="js-modal-cancel-action qa-modal-cancel-button"
              data-dismiss="modal"
              @click="emitCancel($event)"
            >
              {{ s__('Modal|Cancel') }}
            </gl-button>
            <gl-button
              :class="`btn-${footerPrimaryButtonVariant}`"
              class="js-modal-primary-action qa-modal-primary-button"
              data-dismiss="modal"
              @click="emitSubmit($event)"
            >
              {{ footerPrimaryButtonText }}
            </gl-button>
          </slot>
        </div>
      </div>
    </div>
  </div>
</template>
