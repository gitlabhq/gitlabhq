<script>
import { GlLink, GlFormGroup, GlFormCheckbox } from '@gitlab/ui';
import IntegrationHelpText from '~/vue_shared/components/integrations_help_text.vue';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';

const toCheckboxValue = (bool) => (bool ? '1' : false);

export default {
  name: 'IntegrationView',
  components: {
    GlLink,
    GlFormGroup,
    GlFormCheckbox,
    IntegrationHelpText,
    HelpIcon,
  },
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
    value: {
      type: Boolean,
      required: true,
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      checkboxValue: toCheckboxValue(this.value),
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
  watch: {
    value(val) {
      this.checkboxValue = toCheckboxValue(val);
    },
    checkboxValue(val) {
      // note: When checked we get '1' since we set `value` prop. Unchecked is `false` as expected.
      //       This value="1" needs to be set to properly handle the Rails form.
      //       https://bootstrap-vue.org/docs/components/form-checkbox#comp-ref-b-form-checkbox-props
      this.$emit('input', Boolean(val));
    },
  },
};
</script>

<template>
  <gl-form-group>
    <template #label>
      {{ title || config.title }}
      <gl-link class="has-tooltip" title="More information" :href="helpLink">
        <help-icon class="vertical-align-middle" />
      </gl-link>
    </template>
    <!-- Necessary for Rails to receive the value when not checked -->
    <input
      :name="formName"
      type="hidden"
      value="0"
      data-testid="profile-preferences-integration-hidden-field"
    />
    <gl-form-checkbox :id="formId" v-model="checkboxValue" :name="formName" value="1"
      >{{ config.label }}
      <template #help>
        <integration-help-text :message="message" :message-url="messageUrl" />
      </template>
    </gl-form-checkbox>
  </gl-form-group>
</template>
