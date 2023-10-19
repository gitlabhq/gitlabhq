<script>
import {
  GlForm,
  GlFormFields,
  GlButton,
  GlFormInputGroup,
  GlFormInput,
  GlInputGroupText,
  GlTruncate,
} from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { s__, __ } from '~/locale';
import { slugify } from '~/lib/utils/text_utility';
import { joinPaths } from '~/lib/utils/url_utility';

export default {
  name: 'NewEditForm',
  components: {
    GlForm,
    GlFormFields,
    GlButton,
    GlFormInputGroup,
    GlFormInput,
    GlInputGroupText,
    GlTruncate,
  },
  i18n: {
    createOrganization: s__('Organization|Create organization'),
    cancel: __('Cancel'),
    pathPlaceholder: s__('Organization|my-organization'),
  },
  formId: 'new-organization-form',
  fields: {
    name: {
      label: s__('Organization|Organization name'),
      validators: [formValidators.required(s__('Organization|Organization name is required.'))],
      groupAttrs: {
        description: s__(
          'Organization|Must start with a letter, digit, emoji, or underscore. Can also contain periods, dashes, spaces, and parentheses.',
        ),
      },
      inputAttrs: {
        class: 'gl-md-form-input-lg',
        placeholder: s__('Organization|My organization'),
      },
    },
    path: {
      label: s__('Organization|Organization URL'),
      validators: [formValidators.required(s__('Organization|Organization URL is required.'))],
    },
  },
  inject: ['organizationsPath', 'rootUrl'],
  props: {
    loading: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      formValues: {
        name: '',
        path: '',
      },
      hasPathBeenManuallySet: false,
    };
  },
  computed: {
    baseUrl() {
      return joinPaths(this.rootUrl, this.organizationsPath, '/');
    },
  },
  watch: {
    'formValues.name': function watchName(value) {
      if (this.hasPathBeenManuallySet) {
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
  },
};
</script>

<template>
  <gl-form :id="$options.formId">
    <gl-form-fields
      v-model="formValues"
      :form-id="$options.formId"
      :fields="$options.fields"
      @submit="$emit('submit', formValues)"
    >
      <template #input(path)="{ id, value, validation, input, blur }">
        <gl-form-input-group>
          <template #prepend>
            <gl-input-group-text class="organization-root-path">
              <gl-truncate :text="baseUrl" position="middle" />
            </gl-input-group-text>
          </template>
          <gl-form-input
            v-bind="validation"
            :id="id"
            :value="value"
            :placeholder="$options.i18n.pathPlaceholder"
            class="gl-h-auto! gl-md-form-input-lg"
            @input="onPathInput($event, input)"
            @blur="blur"
          />
        </gl-form-input-group>
      </template>
    </gl-form-fields>
    <div class="gl-display-flex gl-gap-3">
      <gl-button type="submit" variant="confirm" class="js-no-auto-disable" :loading="loading">{{
        $options.i18n.createOrganization
      }}</gl-button>
      <gl-button :href="organizationsPath">{{ $options.i18n.cancel }}</gl-button>
    </div>
  </gl-form>
</template>
