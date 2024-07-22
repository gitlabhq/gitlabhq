<script>
import { GlForm, GlFormFields, GlButton } from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { n__, s__, __ } from '~/locale';
import { slugify } from '~/lib/utils/text_utility';
import AvatarUploadDropzone from '~/vue_shared/components/upload_dropzone/avatar_upload_dropzone.vue';
import MarkdownField from '~/vue_shared/components/markdown/field.vue';
import { RESTRICTED_TOOLBAR_ITEMS_BASIC_EDITING_ONLY } from '~/vue_shared/components/markdown/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  FORM_FIELD_NAME,
  FORM_FIELD_ID,
  FORM_FIELD_PATH,
  FORM_FIELD_DESCRIPTION,
  FORM_FIELD_AVATAR,
  MAX_DESCRIPTION_COUNT,
  FORM_FIELD_PATH_VALIDATORS,
  FORM_FIELD_DESCRIPTION_VALIDATORS,
} from '../constants';
import OrganizationUrlField from './organization_url_field.vue';

export default {
  name: 'NewEditForm',
  components: {
    GlForm,
    GlFormFields,
    GlButton,
    OrganizationUrlField,
    AvatarUploadDropzone,
    MarkdownField,
  },
  i18n: {
    cancel: __('Cancel'),
    charactersRemaining: (char) => n__('%d character remaining', '%d characters remaining', char),
    charactersOverLimit: (char) => n__('%d character over limit', '%d characters over limit', char),
  },
  formId: 'organization-form',
  markdownDocsPath: helpPagePath('user/organization/index', {
    anchor: 'supported-markdown-for-organization-description',
  }),
  restrictedToolBarItems: RESTRICTED_TOOLBAR_ITEMS_BASIC_EDITING_ONLY,
  inject: ['organizationsPath', 'previewMarkdownPath'],
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
          [FORM_FIELD_PATH]: '',
          [FORM_FIELD_DESCRIPTION]: '',
          [FORM_FIELD_AVATAR]: null,
        };
      },
    },
    fieldsToRender: {
      type: Array,
      required: false,
      default() {
        return [FORM_FIELD_NAME, FORM_FIELD_PATH, FORM_FIELD_DESCRIPTION, FORM_FIELD_AVATAR];
      },
    },
    submitButtonText: {
      type: String,
      required: false,
      default: s__('Organization|Create organization'),
    },
    showCancelButton: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      formValues: this.initialFormValues,
      hasPathBeenManuallySet: false,
    };
  },
  computed: {
    fields() {
      const fields = {
        [FORM_FIELD_NAME]: {
          label: s__('Organization|Organization name'),
          validators: [formValidators.required(s__('Organization|Organization name is required.'))],
          groupAttrs: {
            class: 'gl-w-full',
            description: s__(
              'Organization|Must start with a letter, digit, emoji, or underscore. Can also contain periods, dashes, spaces, and parentheses.',
            ),
          },
          inputAttrs: {
            class: 'gl-md-form-input-lg',
            placeholder: s__('Organization|My organization'),
            'data-testid': 'organization-name',
          },
        },
        [FORM_FIELD_ID]: {
          label: s__('Organization|Organization ID'),
          groupAttrs: {
            class: 'gl-w-full',
          },
          inputAttrs: {
            class: 'gl-md-form-input-lg',
            disabled: true,
          },
        },
        [FORM_FIELD_PATH]: {
          label: s__('Organization|Organization URL'),
          validators: FORM_FIELD_PATH_VALIDATORS,
          groupAttrs: {
            class: 'gl-w-full',
          },
        },
        [FORM_FIELD_DESCRIPTION]: {
          label: s__('Organization|Organization description (optional)'),
          validators: FORM_FIELD_DESCRIPTION_VALIDATORS,
          groupAttrs: {
            class: 'gl-w-full common-note-form',
          },
        },
        [FORM_FIELD_AVATAR]: {
          label: s__('Organization|Organization avatar'),
          groupAttrs: {
            class: 'gl-w-full',
            labelSrOnly: true,
          },
        },
      };

      return Object.entries(fields).reduce((accumulator, [fieldKey, fieldDefinition]) => {
        if (!this.fieldsToRender.includes(fieldKey)) {
          return accumulator;
        }

        return {
          ...accumulator,
          [fieldKey]: fieldDefinition,
        };
      }, {});
    },
    textareaCharacterCounter() {
      const remainingCharacters =
        MAX_DESCRIPTION_COUNT - (this.formValues[FORM_FIELD_DESCRIPTION] || '').length;

      if (remainingCharacters >= 0) {
        return {
          class: 'gl-text-gray-500',
          text: this.$options.i18n.charactersRemaining(remainingCharacters),
        };
      }

      return {
        class: 'gl-text-red-500',
        text: this.$options.i18n.charactersOverLimit(Math.abs(remainingCharacters)),
      };
    },
  },
  watch: {
    'formValues.name': function watchName(value) {
      if (this.hasPathBeenManuallySet || !this.fieldsToRender.includes(FORM_FIELD_PATH)) {
        return;
      }

      this.formValues.path = slugify(value);
    },
  },
  methods: {
    onPathInput(event, formFieldsInputEvent) {
      formFieldsInputEvent(event);
      this.hasPathBeenManuallySet = true;
    },
    helpPagePath,
  },
};
</script>

<template>
  <gl-form :id="$options.formId">
    <gl-form-fields
      v-model="formValues"
      :form-id="$options.formId"
      :fields="fields"
      class="gl-flex gl-flex-wrap gl-gap-x-5"
      @submit="$emit('submit', formValues)"
    >
      <template #input(path)="{ id, value, validation, input, blur }">
        <organization-url-field
          :id="id"
          :value="value"
          :validation="validation"
          @input="onPathInput($event, input)"
          @blur="blur"
        />
      </template>
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
      <template #input(avatar)="{ input, value }">
        <avatar-upload-dropzone
          :value="value"
          :entity="formValues"
          :label="fields.avatar.label"
          @input="input"
        />
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
      <gl-button v-if="showCancelButton" :href="organizationsPath">{{
        $options.i18n.cancel
      }}</gl-button>
    </div>
  </gl-form>
</template>
