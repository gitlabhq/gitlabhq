<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlForm, GlFormGroup, GlFormInput, GlAlert } from '@gitlab/ui';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { logError } from '~/lib/logger';
import { __ } from '~/locale';
import { InternalEvents } from '~/tracking';
import createSavedReplyMutation from '../queries/create_saved_reply.mutation.graphql';
import updateSavedReplyMutation from '../queries/update_saved_reply.mutation.graphql';

export default {
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlAlert,
    MarkdownField,
  },
  mixins: [InternalEvents.mixin()],
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
          mutation: this.id ? updateSavedReplyMutation : createSavedReplyMutation,
          variables: {
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
              this.track_event('i_code_review_saved_replies_create');
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
  restrictedToolbarItems: ['full-screen'],
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
      class="gl-lg-max-w-80p"
    >
      <markdown-field
        :enable-preview="false"
        :is-submitting="saving"
        :add-spacing-classes="false"
        :textarea-value="updateCommentTemplate.content"
        :markdown-docs-path="$options.markdownDocsPath"
        :restricted-tool-bar-items="$options.restrictedToolbarItems"
        :force-autosize="false"
        class="js-no-autosize gl-border-gray-400!"
      >
        <template #textarea>
          <textarea
            v-model="updateCommentTemplate.content"
            dir="auto"
            class="note-textarea js-gfm-input js-autosize markdown-area"
            data-supports-quick-actions="false"
            :aria-label="__('Content')"
            :placeholder="__('Write comment template content here…')"
            data-testid="comment-template-content-input"
            @keydown.meta.enter="onSubmit"
            @keydown.ctrl.enter="onSubmit"
          ></textarea>
        </template>
      </markdown-field>
    </gl-form-group>
    <gl-button
      variant="confirm"
      class="gl-mr-3 js-no-auto-disable"
      type="submit"
      :loading="saving"
      data-testid="comment-template-form-submit-btn"
    >
      {{ __('Save') }}
    </gl-button>
    <gl-button @click="onCancel">{{ __('Cancel') }}</gl-button>
  </gl-form>
</template>
