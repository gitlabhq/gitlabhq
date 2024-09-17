<script>
import { GlForm, GlFormInput, GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

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
    isIssueTitleEmpty() {
      return this.title.trim() === '';
    },
    isCreatingIssueDisabled() {
      return this.isIssueTitleEmpty || this.disableSubmit;
    },
  },
  methods: {
    handleFormCancel() {
      this.title = '';
      this.$emit('form-cancel');
    },
    handleFormSubmit() {
      const { title, list } = this;

      this.$emit('form-submit', {
        title: title.trim(),
        list,
      });
    },
  },
};
</script>

<template>
  <div class="board-new-issue-form gl-z-3 gl-m-3">
    <div class="board-card position-relative rounded gl-p-5">
      <gl-form @submit.prevent="handleFormSubmit" @reset="handleFormCancel">
        <label :for="inputFieldId" class="gl-font-bold">{{ __('Title') }}</label>
        <gl-form-input
          :id="inputFieldId"
          v-model="title"
          :autofocus="true"
          autocomplete="off"
          type="text"
          name="issue_title"
        />
        <slot></slot>
        <div class="gl-mt-4 gl-clearfix">
          <gl-button
            data-testid="create-button"
            :disabled="isCreatingIssueDisabled"
            class="js-no-auto-disable gl-float-left"
            variant="confirm"
            type="submit"
          >
            {{ submitButtonTitle }}
          </gl-button>
          <gl-button class="js-no-auto-disable gl-float-right" type="reset">
            {{ $options.i18n.cancel }}
          </gl-button>
        </div>
      </gl-form>
    </div>
  </div>
</template>
