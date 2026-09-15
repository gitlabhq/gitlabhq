<script>
import { GlButton, GlForm, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import {
  NAME_MAX_LENGTH,
  TEMPLATE_MAX_LENGTH,
  validateEntry,
  validateName,
  validateTemplate,
} from './constants';

export default {
  name: 'CodeDropdownClientForm',
  components: { GlButton, GlForm, GlFormGroup, GlFormInput },
  props: {
    client: {
      type: Object,
      required: false,
      default: null,
    },
    otherClients: {
      type: Array,
      required: false,
      default: () => [],
    },
    isSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['submit', 'cancel'],
  data() {
    return {
      name: this.client?.name ?? '',
      sshUrlTemplate: this.client?.ssh_url_template ?? '',
      httpUrlTemplate: this.client?.http_url_template ?? '',
      submitted: false,
    };
  },
  computed: {
    isEdit() {
      return this.client !== null;
    },
    submitText() {
      return this.isEdit ? __('Save') : __('Add');
    },
    nameError() {
      return validateName(this.name, { others: this.otherClients });
    },
    sshUrlTemplateError() {
      return (
        validateTemplate(this.sshUrlTemplate, { others: this.otherClients }) || this.entryError
      );
    },
    httpUrlTemplateError() {
      return (
        validateTemplate(this.httpUrlTemplate, { others: this.otherClients }) || this.entryError
      );
    },
    entryError() {
      return validateEntry({
        sshUrlTemplate: this.sshUrlTemplate,
        httpUrlTemplate: this.httpUrlTemplate,
      });
    },
    isValid() {
      return !this.nameError && !this.sshUrlTemplateError && !this.httpUrlTemplateError;
    },
  },
  methods: {
    // Errors stay hidden until the first submit attempt, so a half-typed entry does not
    // light up red while the admin is still filling it in.
    fieldState(error) {
      return this.submitted && error ? false : null;
    },
    onSubmit() {
      this.submitted = true;

      if (!this.isValid) return;

      this.$emit('submit', {
        name: this.name.trim(),
        ssh_url_template: this.sshUrlTemplate.trim(),
        http_url_template: this.httpUrlTemplate.trim(),
      });
    },
  },
  i18n: {
    name: s__('CodeDropdownClients|Display name'),
    nameDescription: s__(
      'CodeDropdownClients|Define the name of the client shown to users in the Code dropdown.',
    ),
    sshUrlTemplate: __('SSH URL template'),
    httpUrlTemplate: __('HTTPS URL template'),
    templateDescription: s__('CodeDropdownClients|Use {url} as the placeholder for the clone URL.'),
    templatePlaceholder: 'example://example.git/clone?url={url}',
    cancel: __('Cancel'),
  },
  NAME_MAX_LENGTH,
  TEMPLATE_MAX_LENGTH,
};
</script>

<template>
  <gl-form @submit.prevent="onSubmit">
    <gl-form-group
      :label="$options.i18n.name"
      :description="$options.i18n.nameDescription"
      :state="fieldState(nameError)"
      :invalid-feedback="nameError"
      label-for="code-dropdown-client-name"
    >
      <gl-form-input
        id="code-dropdown-client-name"
        v-model="name"
        :maxlength="$options.NAME_MAX_LENGTH"
        :state="fieldState(nameError)"
        data-testid="client-name-input"
      />
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.sshUrlTemplate"
      :description="$options.i18n.templateDescription"
      :state="fieldState(sshUrlTemplateError)"
      :invalid-feedback="sshUrlTemplateError"
      label-for="code-dropdown-client-ssh-template"
    >
      <gl-form-input
        id="code-dropdown-client-ssh-template"
        v-model="sshUrlTemplate"
        :maxlength="$options.TEMPLATE_MAX_LENGTH"
        :placeholder="$options.i18n.templatePlaceholder"
        :state="fieldState(sshUrlTemplateError)"
        data-testid="client-ssh-template-input"
      />
    </gl-form-group>

    <gl-form-group
      :label="$options.i18n.httpUrlTemplate"
      :description="$options.i18n.templateDescription"
      :state="fieldState(httpUrlTemplateError)"
      :invalid-feedback="httpUrlTemplateError"
      label-for="code-dropdown-client-http-template"
    >
      <gl-form-input
        id="code-dropdown-client-http-template"
        v-model="httpUrlTemplate"
        :maxlength="$options.TEMPLATE_MAX_LENGTH"
        :placeholder="$options.i18n.templatePlaceholder"
        :state="fieldState(httpUrlTemplateError)"
        data-testid="client-http-template-input"
      />
    </gl-form-group>

    <div class="gl-flex gl-gap-3">
      <gl-button
        type="submit"
        variant="confirm"
        :loading="isSaving"
        data-testid="submit-client-button"
      >
        {{ submitText }}
      </gl-button>
      <gl-button
        type="button"
        :disabled="isSaving"
        data-testid="cancel-client-button"
        @click="$emit('cancel')"
      >
        {{ $options.i18n.cancel }}
      </gl-button>
    </div>
  </gl-form>
</template>
