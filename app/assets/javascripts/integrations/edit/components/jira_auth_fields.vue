<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { isEmpty } from 'lodash';
import { GlFormGroup, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { __, s__ } from '~/locale';

import { jiraIntegrationAuthFields, jiraAuthTypeFieldProps } from '~/integrations/constants';
import DynamicField from './dynamic_field.vue';

const authTypeOptions = [
  {
    value: 0,
    text: s__('JiraService|Basic'),
  },
  {
    value: 1,
    text: s__('JiraService|Jira personal access token'),
    help: s__('JiraService|Recommended. Only available for Jira Data Center and Jira Server.'),
  },
];

export default {
  name: 'JiraAuthFields',

  components: {
    GlFormGroup,
    GlFormRadio,
    GlFormRadioGroup,
    DynamicField,
  },

  props: {
    isValidated: {
      type: Boolean,
      required: false,
      default: false,
    },

    fields: {
      type: Array,
      required: false,
      default: () => [],
    },
  },

  data() {
    return {
      authType: 0,
    };
  },

  computed: {
    ...mapGetters(['currentKey', 'isInheriting']),

    isAuthTypeBasic() {
      return this.authType === 0;
    },

    isNonEmptyPassword() {
      return !isEmpty(this.passwordField?.value);
    },

    authTypeProps() {
      return jiraAuthTypeFieldProps[this.authType];
    },

    authTypeField() {
      return this.findFieldByName(jiraIntegrationAuthFields.AUTH_TYPE);
    },

    usernameField() {
      return this.findFieldByName(jiraIntegrationAuthFields.USERNAME);
    },

    passwordField() {
      return this.findFieldByName(jiraIntegrationAuthFields.PASSWORD);
    },

    usernameProps() {
      return {
        ...this.usernameField,
        ...(this.isAuthTypeBasic ? { required: true } : {}),
        title: this.authTypeProps.username,
      };
    },

    passwordProps() {
      const extraProps = this.isNonEmptyPassword
        ? { title: this.authTypeProps.nonEmptyPassword }
        : { title: this.authTypeProps.password, help: this.authTypeProps.passwordHelp };

      return {
        ...this.passwordField,
        ...extraProps,
      };
    },
  },

  mounted() {
    const authTypeValue = this.authTypeField?.value;
    if (authTypeValue) {
      this.authType = parseInt(authTypeValue, 10);
    }
  },

  methods: {
    findFieldByName(name) {
      return this.fields.find((field) => field.name === name);
    },
  },

  authTypeOptions,

  i18n: {
    authTypeLabel: __('Authentication method'),
  },
};
</script>

<template>
  <gl-form-group :label="$options.i18n.authTypeLabel" label-for="service[jira_auth_type]">
    <input name="service[jira_auth_type]" type="hidden" :value="authType" />
    <gl-form-radio-group v-model="authType" :disabled="isInheriting">
      <gl-form-radio
        v-for="option in $options.authTypeOptions"
        :key="option.value"
        :value="option.value"
      >
        <template v-if="option.help" #help>
          {{ option.help }}
        </template>
        {{ option.text }}
      </gl-form-radio>
    </gl-form-radio-group>

    <div class="gl-ml-6 gl-mt-3">
      <dynamic-field
        v-if="isAuthTypeBasic"
        :key="`${currentKey}-${usernameProps.name}`"
        data-testid="jira-auth-username"
        v-bind="usernameProps"
        :is-validated="isValidated"
      />
      <dynamic-field
        :key="`${currentKey}-${passwordProps.name}`"
        data-testid="jira-auth-password"
        v-bind="passwordProps"
        :is-validated="isValidated"
      />
    </div>
  </gl-form-group>
</template>
