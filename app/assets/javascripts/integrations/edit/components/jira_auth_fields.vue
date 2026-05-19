<script>
import { mapState } from 'pinia';
import { isEmpty } from 'lodash-es';
import { GlFormGroup, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';

import {
  jiraAuthTypes,
  jiraIntegrationAuthFields,
  jiraAuthTypeFieldProps,
} from '~/integrations/constants';
import { useIntegrationForm } from '../store';
import DynamicField from './dynamic_field.vue';

const JIRA_CLOUD_ID_DOCS_URL =
  'https://support.atlassian.com/jira/kb/retrieve-my-atlassian-sites-cloud-id/';

const authTypeOptions = [
  {
    value: jiraAuthTypes.BASIC,
    text: s__('JiraService|Basic authentication'),
    help: s__(
      'JiraService|Use an email and API token for Jira Cloud, or a username and password for Jira Data Center or Jira Server.',
    ),
  },
  {
    value: jiraAuthTypes.PAT,
    text: s__('JiraService|Personal access token'),
    help: s__(
      'JiraService|Use a Jira personal access token. Supported for Jira Data Center and Jira Server.',
    ),
  },
  {
    value: jiraAuthTypes.SERVICE_ACCOUNT,
    text: s__('JiraService|Jira Cloud service account'),
    help: s__('JiraService|Use a scoped API token for a Jira Cloud service account.'),
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

    currentAuthType: {
      type: Number,
      required: false,
      default: null,
    },
  },

  emits: ['change-auth-type'],

  data() {
    return {
      authType: this.currentAuthType ?? jiraAuthTypes.BASIC,
    };
  },

  computed: {
    ...mapState(useIntegrationForm, ['currentKey', 'isInheriting']),

    isAuthTypeBasic() {
      return this.authType === jiraAuthTypes.BASIC;
    },

    isServiceAccount() {
      return this.authType === jiraAuthTypes.SERVICE_ACCOUNT;
    },

    isNonEmptyPassword() {
      return !isEmpty(this.passwordField?.value);
    },

    authTypeProps() {
      return jiraAuthTypeFieldProps[this.authType] || {};
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

    urlField() {
      return this.findFieldByName(jiraIntegrationAuthFields.WEB_URL);
    },

    apiUrlField() {
      return this.findFieldByName(jiraIntegrationAuthFields.API_URL);
    },

    urlProps() {
      if (!this.urlField) return {};

      return {
        ...this.urlField,
      };
    },

    apiUrlProps() {
      if (!this.apiUrlField) return {};

      const baseHelp = s__('JiraService|If different from the web URL.');
      const serviceAccountExtra = sprintf(
        s__(
          'JiraService|For Jira Cloud service accounts, use https://api.atlassian.com/ex/jira/{cloudId}. %{linkStart}How to find your Cloud ID%{linkEnd}.',
        ),
        {
          linkStart: `<a href="${JIRA_CLOUD_ID_DOCS_URL}" target="_blank" rel="noopener noreferrer">`,
          linkEnd: '</a>',
        },
        false,
      );

      return {
        ...this.apiUrlField,
        help: this.isServiceAccount ? `${baseHelp} ${serviceAccountExtra}` : baseHelp,
        required: this.isServiceAccount,
      };
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
    const authTypeValue = this.authTypeField?.value ?? this.currentAuthType;

    if (authTypeValue !== undefined && authTypeValue !== null) {
      this.authType = parseInt(authTypeValue, 10);
    }
  },

  methods: {
    findFieldByName(name) {
      return this.fields.find((field) => field.name === name);
    },

    onAuthTypeChange(value) {
      this.$emit('change-auth-type', value);
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

    <gl-form-radio-group
      v-model="authType"
      class="gl-mb-5"
      :disabled="isInheriting"
      @input="onAuthTypeChange"
    >
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
    <dynamic-field
      v-if="urlField"
      :key="`${currentKey}-${urlProps.name}`"
      data-testid="jira-url"
      v-bind="urlProps"
      :is-validated="isValidated"
    />
    <dynamic-field
      v-if="apiUrlField"
      :key="`${currentKey}-${apiUrlProps.name}`"
      data-testid="jira-api-url"
      v-bind="apiUrlProps"
      :is-validated="isValidated"
    />
  </gl-form-group>
</template>
