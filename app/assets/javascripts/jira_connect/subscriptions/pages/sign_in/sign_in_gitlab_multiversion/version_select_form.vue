<script>
import {
  GlForm,
  GlFormGroup,
  GlFormRadioGroup,
  GlFormInput,
  GlFormRadio,
  GlButton,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';

import { GITLAB_COM_BASE_PATH } from '~/jira_connect/subscriptions/constants';

const RADIO_OPTIONS = {
  saas: 'saas',
  selfManaged: 'selfManaged',
};

const DEFAULT_RADIO_OPTION = RADIO_OPTIONS.saas;

export default {
  name: 'VersionSelectForm',
  components: {
    GlForm,
    GlFormGroup,
    GlFormRadioGroup,
    GlFormInput,
    GlFormRadio,
    GlButton,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selected: DEFAULT_RADIO_OPTION,
      selfManagedBasePathInput: '',
    };
  },
  computed: {
    isSelfManagedSelected() {
      return this.selected === RADIO_OPTIONS.selfManaged;
    },
  },
  methods: {
    onSubmit() {
      const gitlabBasePath =
        this.selected === RADIO_OPTIONS.saas ? GITLAB_COM_BASE_PATH : this.selfManagedBasePathInput;
      this.$emit('submit', gitlabBasePath);
    },
  },
  radioOptions: RADIO_OPTIONS,
  i18n: {
    saasRadioLabel: __('GitLab.com (SaaS)'),
    saasRadioHelp: __('Most common'),
    selfManagedRadioLabel: __('GitLab (self-managed)'),
    instanceURLInputLabel: s__('JiraService|GitLab instance URL'),
    instanceURLInputDescription: s__('JiraService|For example: https://gitlab.example.com'),
  },
};
</script>

<template>
  <gl-form class="gl-max-w-62 gl-mx-auto" @submit.prevent="onSubmit">
    <gl-form-radio-group v-model="selected" class="gl-mb-3" name="gitlab_version">
      <gl-form-radio :value="$options.radioOptions.saas">
        {{ $options.i18n.saasRadioLabel }}
        <template #help>
          {{ $options.i18n.saasRadioHelp }}
        </template>
      </gl-form-radio>
      <gl-form-radio :value="$options.radioOptions.selfManaged">
        {{ $options.i18n.selfManagedRadioLabel }}
      </gl-form-radio>
    </gl-form-radio-group>

    <gl-form-group
      v-if="isSelfManagedSelected"
      class="gl-ml-6"
      :label="$options.i18n.instanceURLInputLabel"
      :description="$options.i18n.instanceURLInputDescription"
      label-for="self-managed-instance-input"
    >
      <gl-form-input id="self-managed-instance-input" v-model="selfManagedBasePathInput" required />
    </gl-form-group>

    <div class="gl-display-flex gl-justify-content-end">
      <gl-button variant="confirm" type="submit" :loading="loading">{{ __('Save') }}</gl-button>
    </div>
  </gl-form>
</template>
