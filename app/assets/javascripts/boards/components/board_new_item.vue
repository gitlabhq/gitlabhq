<script>
import { GlForm, GlFormInput, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

import eventHub from '../eventhub';

export default {
  i18n: {
    cancel: __('Cancel'),
  },
  components: {
    GlForm,
    GlFormInput,
    GlButton,
  },
  props: {
    list: {
      type: Object,
      required: true,
    },
    formEventPrefix: {
      type: String,
      required: true,
    },
    disableSubmit: {
      type: Boolean,
      required: false,
      default: false,
    },
    submitButtonTitle: {
      type: String,
      required: false,
      default: __('Create issue'),
    },
  },
  data() {
    return {
      title: '',
    };
  },
  computed: {
    inputFieldId() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${this.list.id}-title`;
    },
  },
  methods: {
    handleFormCancel() {
      this.title = '';
      this.$emit('form-cancel');
    },
    handleFormSubmit() {
      const { title, list } = this;

      eventHub.$emit(`scroll-board-list-${this.list.id}`);
      this.$emit('form-submit', {
        title,
        list,
      });
    },
  },
};
</script>

<template>
  <div class="board-new-issue-form">
    <div class="board-card position-relative gl-p-5 rounded">
      <gl-form @submit.prevent="handleFormSubmit" @reset="handleFormCancel">
        <label :for="inputFieldId" class="gl-font-weight-bold">{{ __('Title') }}</label>
        <gl-form-input
          :id="inputFieldId"
          v-model.trim="title"
          :autofocus="true"
          autocomplete="off"
          type="text"
          name="issue_title"
        />
        <slot></slot>
        <div class="gl-clearfix gl-mt-4">
          <gl-button
            :disabled="!title || disableSubmit"
            class="gl-float-left js-no-auto-disable"
            variant="confirm"
            type="submit"
          >
            {{ submitButtonTitle }}
          </gl-button>
          <gl-button class="gl-float-right js-no-auto-disable" type="reset">
            {{ $options.i18n.cancel }}
          </gl-button>
        </div>
      </gl-form>
    </div>
  </div>
</template>
