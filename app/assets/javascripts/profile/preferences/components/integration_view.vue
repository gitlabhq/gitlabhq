<script>
import { GlIcon, GlLink, GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';

export default {
  name: 'IntegrationView',
  components: {
    GlIcon,
    GlLink,
    GlFormGroup,
    GlFormCheckbox,
    IntegrationHelpText,
  },
  inject: ['userFields'],
  props: {
    helpLink: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    messageUrl: {
      type: String,
      required: true,
    },
    config: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isEnabled: this.userFields[this.config.formName] ? '1' : '0',
    };
  },
  computed: {
    formName() {
      return `user[${this.config.formName}]`;
    },
    formId() {
      return `user_${this.config.formName}`;
    },
  },
};
</script>

<template>
  <gl-form-group>
    <template #label>
      {{ config.title }}
      <gl-link class="has-tooltip" title="More information" :href="helpLink">
        <gl-icon name="question-o" class="vertical-align-middle" />
      </gl-link>
    </template>
    <!-- Necessary for Rails to receive the value when not checked -->
    <input
      :name="formName"
      type="hidden"
      value="0"
      data-testid="profile-preferences-integration-hidden-field"
    />
    <gl-form-checkbox :id="formId" :checked="isEnabled" :name="formName" value="1"
      >{{ config.label }}
      <template #help>
        <integration-help-text :message="message" :message-url="messageUrl" />
      </template>
    </gl-form-checkbox>
  </gl-form-group>
</template>
