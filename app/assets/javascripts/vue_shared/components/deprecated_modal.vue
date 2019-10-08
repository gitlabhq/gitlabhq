<script>
/* eslint-disable vue/require-default-prop */
import { __ } from '~/locale';

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
      default: __('Cancel'),
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
    <div :id="id" :class="id ? '' : 'd-block'" class="modal" role="dialog" tabindex="-1">
      <div :class="modalDialogClass" class="modal-dialog" role="document">
        <div class="modal-content">
          <div class="modal-header">
            <slot name="header">
              <h4 class="modal-title float-left">{{ title }}</h4>
              <button
                type="button"
                class="close float-right"
                data-dismiss="modal"
                :aria-label="__('Close')"
                @click="emitCancel($event)"
              >
                <span aria-hidden="true">&times;</span>
              </button>
            </slot>
          </div>
          <div class="modal-body">
            <slot :text="text" name="body">
              <p>{{ text }}</p>
            </slot>
          </div>
          <div v-if="!hideFooter" class="modal-footer">
            <button
              :class="btnCancelKindClass"
              type="button"
              class="btn"
              data-dismiss="modal"
              @click="emitCancel($event)"
            >
              {{ closeButtonLabel }}
            </button>

            <slot v-if="secondaryButtonLabel" name="secondary-button">
              <button v-if="secondaryButtonLabel" type="button" class="btn" data-dismiss="modal">
                {{ secondaryButtonLabel }}
              </button>
            </slot>

            <button
              v-if="primaryButtonLabel"
              :disabled="submitDisabled"
              :class="btnKindClass"
              type="button"
              class="btn js-primary-button"
              data-dismiss="modal"
              data-qa-selector="save_changes_button"
              @click="emitSubmit($event)"
            >
              {{ primaryButtonLabel }}
            </button>
          </div>
        </div>
      </div>
    </div>
    <div v-if="!id" class="modal-backdrop fade show"></div>
  </div>
</template>
