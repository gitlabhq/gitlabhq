<script>
import { GlFormText, GlIcon, GlLink } from '@gitlab/ui';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';

export default {
  name: 'IntegrationView',
  components: {
    GlFormText,
    GlIcon,
    GlLink,
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
      isEnabled: this.userFields[this.config.formName],
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
  <div>
    <label class="label-bold">
      {{ config.title }}
    </label>
    <gl-link class="has-tooltip" title="More information" :href="helpLink">
      <gl-icon name="question-o" class="vertical-align-middle" />
    </gl-link>
    <div class="form-group form-check" data-testid="profile-preferences-integration-form-group">
      <!-- Necessary for Rails to receive the value when not checked -->
      <input
        :name="formName"
        type="hidden"
        value="0"
        data-testid="profile-preferences-integration-hidden-field"
      />
      <input
        :id="formId"
        v-model="isEnabled"
        type="checkbox"
        class="form-check-input"
        :name="formName"
        value="1"
        data-testid="profile-preferences-integration-checkbox"
      />
      <label class="form-check-label" :for="formId">
        {{ config.label }}
      </label>
      <gl-form-text tag="div">
        <integration-help-text :message="message" :message-url="messageUrl" />
      </gl-form-text>
    </div>
  </div>
</template>
