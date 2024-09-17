<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlForm, GlFormGroup, GlFormInput, GlAlert } from '@gitlab/ui';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { logError } from '~/lib/logger';
import { __ } from '~/locale';
import { InternalEvents } from '~/tracking';
import Api from '~/api';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlAlert,
    MarkdownEditor,
  },
  mixins: [InternalEvents.mixin()],
  inject: {
    namespaceId: { default: undefined },
    createMutation: { required: true },
    updateMutation: { required: true },
  },
  props: {
    id: {
      type: String,
      required: false,
      default: null,
    },
    name: {
      type: String,
      required: false,
      default: '',
    },
    content: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      errors: [],
      saving: false,
      showValidation: false,
      updateCommentTemplate: {
        name: this.name,
        content: this.content,
      },
      formFieldProps: {
        id: 'comment-template-content',
        name: 'comment-template-content',
        'aria-label': __('Content'),
        placeholder: __('Write comment template content here…'),
        'data-testid': 'comment-template-content-input',
        class: 'note-textarea js-gfm-input js-autosize markdown-area',
      },
    };
  },
  computed: {
    isNameValid() {
      if (this.showValidation) return Boolean(this.updateCommentTemplate.name);

      return true;
    },
    isContentValid() {
      if (this.showValidation) return Boolean(this.updateCommentTemplate.content);

      return true;
    },
    isValid() {
      return this.isNameValid && this.isContentValid;
    },
    markdownPath() {
      return Api.buildUrl(Api.markdownPath);
    },
  },
  methods: {
    onCancel() {
      if (this.id) {
        this.$router.push({ path: '/' });
      } else {
        this.$emit('cancel');
      }
    },
    onSubmit() {
      this.showValidation = true;

      if (!this.isValid) return;

      this.errors = [];
      this.saving = true;

      this.$apollo
        .mutate({
          mutation: this.id ? this.updateMutation : this.createMutation,
          variables: {
            namespaceId: this.namespaceId,
            id: this.id,
            name: this.updateCommentTemplate.name,
            content: this.updateCommentTemplate.content,
          },
          update: (store, { data: { savedReplyMutation } }) => {
            if (savedReplyMutation.errors.length) {
              this.errors = savedReplyMutation.errors.map((e) => e);
            } else {
              this.$emit('saved');
              this.updateCommentTemplate = { name: '', content: '' };
              this.showValidation = false;
              this.trackEvent('i_code_review_saved_replies_create');
            }
          },
        })
        .catch((error) => {
          const errors = error.graphQLErrors;

          if (errors?.length) {
            this.errors = errors.map((e) => e.message);
          } else {
            // Let's be sure to log the original error so it isn't just swallowed.
            // Also, we don't want to translate console messages.
            // eslint-disable-next-line @gitlab/require-i18n-strings
            logError('Unexpected error while saving reply', error);

            this.errors = [__('An unexpected error occurred. Please try again.')];
          }
        })
        .finally(() => {
          this.saving = false;
        });
    },
  },
  markdownDocsPath: helpPagePath('user/markdown'),
};
</script>

<template>
  <gl-form
    class="new-note common-note-form"
    data-testid="comment-template-form"
    @submit.prevent="onSubmit"
  >
    <gl-alert
      v-for="error in errors"
      :key="error"
      variant="danger"
      class="gl-mb-3"
      :dismissible="false"
    >
      {{ error }}
    </gl-alert>
    <gl-form-group
      :label="__('Name')"
      :state="isNameValid"
      :invalid-feedback="__('Please enter a name for the comment template.')"
      data-testid="comment-template-name-form-group"
    >
      <gl-form-input
        v-model="updateCommentTemplate.name"
        :placeholder="__('Enter a name for your comment template')"
        data-testid="comment-template-name-input"
        class="gl-form-input-xl"
      />
    </gl-form-group>
    <gl-form-group
      :label="__('Content')"
      :state="isContentValid"
      :invalid-feedback="__('Please enter the comment template content.')"
      data-testid="comment-template-content-form-group"
      class="lg:gl-max-w-8/10"
    >
      <markdown-editor
        v-model="updateCommentTemplate.content"
        class="js-no-autosize"
        :is-submitting="saving"
        :disable-attachments="true"
        :render-markdown-path="markdownPath"
        :markdown-docs-path="$options.markdownDocsPath"
        :form-field-props="formFieldProps"
        :restricted-tool-bar-items="$options.restrictedToolbarItems"
        :force-autosize="false"
        @keydown.meta.enter="onSubmit"
        @keydown.ctrl.enter="onSubmit"
      />
    </gl-form-group>
    <div class="gl-flex gl-gap-3">
      <gl-button
        variant="confirm"
        class="js-no-auto-disable"
        type="submit"
        :loading="saving"
        data-testid="comment-template-form-submit-btn"
      >
        {{ __('Save') }}
      </gl-button>
      <gl-button @click="onCancel">{{ __('Cancel') }}</gl-button>
    </div>
  </gl-form>
</template>
