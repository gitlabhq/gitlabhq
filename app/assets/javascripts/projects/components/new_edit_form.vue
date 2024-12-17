<script>
import { GlForm, GlFormFields, GlButton } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { n__, s__, __ } from '~/locale';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { RESTRICTED_TOOLBAR_ITEMS_BASIC_EDITING_ONLY } from '~/vue_shared/components/markdown/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  FORM_FIELD_NAME,
  FORM_FIELD_ID,
  FORM_FIELD_DESCRIPTION,
  MAX_DESCRIPTION_COUNT,
  FORM_FIELD_DESCRIPTION_VALIDATORS,
} from './constants';

export default {
  name: 'NewEditForm',
  components: {
    GlForm,
    GlFormFields,
    GlButton,
    MarkdownField,
  },
  i18n: {
    cancel: __('Cancel'),
    charactersRemaining: (char) => n__('%d character remaining', '%d characters remaining', char),
    charactersOverLimit: (char) => n__('%d character over limit', '%d characters over limit', char),
  },
  formId: 'new-edit-project-form',
  markdownDocsPath: helpPagePath('user/markdown'),
  restrictedToolBarItems: RESTRICTED_TOOLBAR_ITEMS_BASIC_EDITING_ONLY,
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
    initialFormValues: {
      type: Object,
      required: false,
      default() {
        return {
          [FORM_FIELD_NAME]: '',
          [FORM_FIELD_ID]: '',
          [FORM_FIELD_DESCRIPTION]: '',
        };
      },
    },
    serverValidations: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
    submitButtonText: {
      type: String,
      required: false,
      default: __('Save changes'),
    },
    previewMarkdownPath: {
      type: String,
      required: true,
    },
    cancelButtonHref: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      formValues: this.initialFormValues,
    };
  },
  computed: {
    fields() {
      const fields = {
        [FORM_FIELD_NAME]: {
          label: s__('ProjectsNew|Project name'),
          validators: [formValidators.required(s__('ProjectsNewEdit|Project name is required.'))],
          groupAttrs: {
            class: 'gl-w-full',
            description: s__(
              'ProjectsNewEdit|Must start with a letter, digit, emoji, or underscore. Can also contain periods, dashes, spaces, and parentheses.',
            ),
          },
          inputAttrs: {
            class: 'gl-md-form-input-lg',
            placeholder: s__('ProjectsNewEdit|My awesome project'),
          },
        },
        [FORM_FIELD_ID]: {
          label: __('Project ID'),
          groupAttrs: {
            class: 'gl-w-full',
          },
          inputAttrs: {
            class: 'gl-md-form-input-lg',
            disabled: true,
          },
        },
        [FORM_FIELD_DESCRIPTION]: {
          label: s__('ProjectsNewEdit|Project description (optional)'),
          validators: FORM_FIELD_DESCRIPTION_VALIDATORS,
          groupAttrs: {
            class: 'gl-w-full common-note-form',
          },
        },
      };

      return fields;
    },
    textareaCharacterCounter() {
      const remainingCharacters =
        MAX_DESCRIPTION_COUNT - (this.formValues[FORM_FIELD_DESCRIPTION] || '').length;

      if (remainingCharacters >= 0) {
        return {
          class: 'gl-text-subtle',
          text: this.$options.i18n.charactersRemaining(remainingCharacters),
        };
      }

      return {
        class: 'gl-text-red-500',
        text: this.$options.i18n.charactersOverLimit(Math.abs(remainingCharacters)),
      };
    },
  },
};
</script>

<template>
  <gl-form :id="$options.formId">
    <gl-form-fields
      v-model="formValues"
      :form-id="$options.formId"
      :fields="fields"
      :server-validations="serverValidations"
      class="gl-flex gl-flex-wrap gl-gap-x-5"
      @submit="$emit('submit', formValues)"
      @input-field="$emit('input-field', $event)"
    >
      <template #input(description)="{ id, value, input, blur }">
        <div class="gl-md-form-input-xl">
          <markdown-field
            class="gl-mb-2"
            :can-attach-file="false"
            :markdown-preview-path="previewMarkdownPath"
            :markdown-docs-path="$options.markdownDocsPath"
            :textarea-value="value || ''"
            :restricted-tool-bar-items="$options.restrictedToolBarItems"
          >
            <template #textarea>
              <textarea
                :id="id"
                :value="value"
                class="note-textarea js-gfm-input markdown-area"
                @input="input($event.target.value)"
                @blur="blur"
              ></textarea>
            </template>
          </markdown-field>
          <span
            data-testid="description-character-counter"
            :class="textareaCharacterCounter.class"
            >{{ textareaCharacterCounter.text }}</span
          >
        </div>
      </template>
    </gl-form-fields>
    <div class="gl-flex gl-gap-3">
      <gl-button
        type="submit"
        variant="confirm"
        class="js-no-auto-disable"
        :loading="loading"
        data-testid="submit-button"
        >{{ submitButtonText }}</gl-button
      >
      <gl-button :href="cancelButtonHref">{{ $options.i18n.cancel }}</gl-button>
    </div>
  </gl-form>
</template>
