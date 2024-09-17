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
import SelfManagedAlert from './self_managed_alert.vue';
import DotComAlert from './dot_com_alert.vue';
import SetupInstructions from './setup_instructions.vue';

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
    SelfManagedAlert,
    DotComAlert,
    SetupInstructions,
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
      showSetupInstructions: false,
      showSelfManagedInstanceInput: false,
    };
  },
  computed: {
    isSelfManagedSelected() {
      return this.selected === RADIO_OPTIONS.selfManaged;
    },
    submitText() {
      return this.isSelfManagedSelected
        ? this.$options.i18n.buttonNext
        : this.$options.i18n.buttonSave;
    },
    showVersionSelect() {
      return !this.showSetupInstructions && !this.showSelfManagedInstanceInput;
    },
  },
  methods: {
    onSubmit() {
      if (this.isSelfManagedSelected && !this.showSelfManagedInstanceInput) {
        this.showSetupInstructions = true;
        return;
      }

      const gitlabBasePath = this.isSelfManagedSelected
        ? this.selfManagedBasePathInput
        : GITLAB_COM_BASE_PATH;
      this.$emit('submit', gitlabBasePath);
    },

    onSetupNext() {
      this.showSetupInstructions = false;
      this.showSelfManagedInstanceInput = true;
    },

    onSetupBack() {
      this.showSetupInstructions = false;
      this.showSelfManagedInstanceInput = false;
    },
  },
  radioOptions: RADIO_OPTIONS,
  i18n: {
    title: s__('JiraConnect|What version of GitLab are you using?'),
    saasRadioLabel: __('GitLab.com (SaaS)'),
    saasRadioHelp: __('Most common'),
    selfManagedRadioLabel: __('GitLab (self-managed)'),
    buttonNext: __('Next'),
    buttonSave: __('Save'),
    instanceURLInputLabel: s__('JiraConnect|GitLab instance URL'),
    instanceURLInputDescription: s__('JiraConnect|For example: https://gitlab.example.com'),
  },
};
</script>

<template>
  <gl-form class="gl-mx-auto gl-max-w-62" @submit.prevent="onSubmit">
    <div v-if="showVersionSelect">
      <h5 class="gl-mb-5">{{ $options.i18n.title }}</h5>
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
      <self-managed-alert v-if="isSelfManagedSelected" />
      <dot-com-alert v-else />

      <div class="gl-mt-5 gl-flex gl-justify-end">
        <gl-button variant="confirm" type="submit" :loading="loading" data-testid="submit-button">{{
          submitText
        }}</gl-button>
      </div>
    </div>

    <setup-instructions v-else-if="showSetupInstructions" @next="onSetupNext" @back="onSetupBack" />

    <div v-else-if="showSelfManagedInstanceInput">
      <gl-form-group
        :label="$options.i18n.instanceURLInputLabel"
        :description="$options.i18n.instanceURLInputDescription"
        label-for="self-managed-instance-input"
      >
        <gl-form-input
          id="self-managed-instance-input"
          v-model="selfManagedBasePathInput"
          required
        />
      </gl-form-group>
      <div class="gl-flex gl-justify-between">
        <gl-button data-testid="back-button" @click.prevent="onSetupBack">{{
          __('Back')
        }}</gl-button>
        <gl-button variant="confirm" type="submit" :loading="loading">{{
          $options.i18n.buttonSave
        }}</gl-button>
      </div>
    </div>
  </gl-form>
</template>
