<script>
import { GlButton, GlForm, GlFormGroup, GlFormInput, GlAlert } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { logError } from '~/lib/logger';
import { __ } from '~/locale';
import createCustomEmojiMutation from '../queries/create_custom_emoji.mutation.graphql';

export default {
  name: 'CustomEmojiForm',
  components: {
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlAlert,
  },
  inject: {
    groupPath: {
      default: '',
    },
  },
  data() {
    return {
      errors: [],
      saving: false,
      showValidation: false,
      updateCustomEmoji: {
        name: '',
        url: '',
      },
    };
  },
  computed: {
    isNameValid() {
      if (this.showValidation) return Boolean(this.updateCustomEmoji.name);

      return true;
    },
    isUrlValid() {
      if (this.showValidation) return Boolean(this.updateCustomEmoji.url);

      return true;
    },
    isValid() {
      return this.isNameValid && this.isUrlValid;
    },
  },
  methods: {
    onSubmit() {
      this.showValidation = true;

      if (!this.isValid) return;

      this.errors = [];
      this.saving = true;

      this.$apollo
        .mutate({
          mutation: createCustomEmojiMutation,
          variables: {
            groupPath: this.groupPath,
            name: this.updateCustomEmoji.name,
            url: this.updateCustomEmoji.url,
          },
          update: (store, { data: { createCustomEmoji } }) => {
            if (createCustomEmoji.errors.length) {
              this.errors = createCustomEmoji.errors.map((e) => e);
            } else {
              this.$emit('saved');
              this.updateCustomEmoji = { name: '', url: '' };
              this.showValidation = false;
            }
          },
        })
        .catch((error) => {
          const errors = error.graphQLErrors;

          if (errors?.length) {
            this.errors = errors.map((e) => e.message);
          } else {
            // eslint-disable-next-line @gitlab/require-i18n-strings
            logError('Unexpected error while saving emoji', error);

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
  <gl-form class="gl-mb-6" data-testid="custom-emoji-form" @submit.prevent="onSubmit">
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
      :invalid-feedback="__('Please enter a name for the custom emoji.')"
      data-testid="custom-emoji-name-form-group"
    >
      <gl-form-input
        v-model="updateCustomEmoji.name"
        :placeholder="__('eg party_tanuki')"
        data-testid="custom-emoji-name-input"
      />
    </gl-form-group>
    <gl-form-group
      :label="__('URL')"
      :state="isUrlValid"
      :invalid-feedback="__('Please enter a URL for the custom emoji.')"
      data-testid="custom-emoji-url-form-group"
    >
      <gl-form-input
        v-model="updateCustomEmoji.url"
        :placeholder="__('Enter a URL for your custom emoji')"
        data-testid="custom-emoji-url-input"
      />
    </gl-form-group>
    <gl-button
      variant="confirm"
      class="js-no-auto-disable gl-mr-3"
      type="submit"
      :loading="saving"
      data-testid="custom-emoji-form-submit-btn"
    >
      {{ __('Save') }}
    </gl-button>
    <gl-button :to="{ path: '/' }">{{ __('Cancel') }}</gl-button>
  </gl-form>
</template>
