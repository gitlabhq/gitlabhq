<script>
import { GlAlert, GlForm } from '@gitlab/ui';
import axios from 'axios';
// eslint-disable-next-line no-restricted-imports
import { mapState, mapActions, mapGetters } from 'vuex';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import {
  I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
  I18N_DEFAULT_ERROR_MESSAGE,
  I18N_SUCCESSFUL_CONNECTION_MESSAGE,
  INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY,
  INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_IAM,
  INTEGRATION_FORM_TYPE_SLACK,
} from '~/integrations/constants';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import csrf from '~/lib/utils/csrf';
import { testIntegrationSettings } from '../api';
import ActiveCheckbox from './active_checkbox.vue';
import DynamicField from './dynamic_field.vue';
import OverrideDropdown from './override_dropdown.vue';
import TriggerFields from './trigger_fields.vue';
import IntegrationFormSection from './integration_forms/section.vue';
import IntegrationFormActions from './integration_form_actions.vue';

export default {
  name: 'IntegrationForm',
  components: {
    OverrideDropdown,
    ActiveCheckbox,
    TriggerFields,
    DynamicField,
    IntegrationFormActions,
    IntegrationFormSection,
    GlAlert,
    GlForm,
  },
  directives: {
    SafeHtml,
  },
  inject: {
    helpHtml: {
      default: '',
    },
  },
  data() {
    return {
      integrationActive: false,
      isValidated: false,
      isSaving: false,
      isTesting: false,
      isResetting: false,
    };
  },
  computed: {
    ...mapGetters(['currentKey', 'propsSource']),
    ...mapState(['defaultState', 'customState', 'override']),
    isEditable() {
      return this.propsSource.editable;
    },
    hasSections() {
      return this.customState.sections.length !== 0;
    },
    fieldsWithoutSection() {
      return this.hasSections
        ? this.propsSource.fields.filter((field) => !field.section)
        : this.propsSource.fields;
    },
    hasFieldsWithoutSection() {
      return this.fieldsWithoutSection.length;
    },
    isSlackIntegration() {
      return this.propsSource.type === INTEGRATION_FORM_TYPE_SLACK;
    },
    isGoogleArtifactManagementIntegration() {
      return this.propsSource.type === INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_ARTIFACT_REGISTRY;
    },
    isGoogleCloudIAMIntegration() {
      return this.propsSource.type === INTEGRATION_FORM_TYPE_GOOGLE_CLOUD_IAM;
    },
    showHelpHtml() {
      if (
        this.isSlackIntegration ||
        this.isGoogleArtifactManagementIntegration ||
        this.isGoogleCloudIAMIntegration
      ) {
        return this.helpHtml;
      }
      return !this.hasSections && this.helpHtml;
    },
    shouldUpgradeSlack() {
      return (
        this.isSlackIntegration &&
        this.customState.shouldUpgradeSlack &&
        (this.hasFieldsWithoutSection || this.hasSections)
      );
    },
  },
  methods: {
    ...mapActions(['setOverride', 'requestJiraIssueTypes']),
    form() {
      return this.$refs.integrationForm.$el;
    },
    setIsValidated() {
      this.isValidated = true;
    },
    onSaveClick() {
      this.isSaving = true;
      if (this.integrationActive && !this.form().checkValidity()) {
        this.isSaving = false;
        this.setIsValidated();
        return;
      }

      this.form().submit();
    },
    onTestClick() {
      if (!this.form().checkValidity()) {
        this.setIsValidated();
        return;
      }

      this.isTesting = true;

      testIntegrationSettings(this.propsSource.testPath, this.getFormData())
        .then(
          ({
            data: {
              error,
              message = I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
              service_response: serviceResponse,
            },
          }) => {
            if (error) {
              const errorMessage = serviceResponse ? [message, serviceResponse].join(' ') : message;
              this.setIsValidated();
              this.$toast.show(errorMessage);
              return;
            }

            this.$toast.show(I18N_SUCCESSFUL_CONNECTION_MESSAGE);
          },
        )
        .catch((error) => {
          this.$toast.show(I18N_DEFAULT_ERROR_MESSAGE);
          Sentry.captureException(error);
        })
        .finally(() => {
          this.isTesting = false;
        });
    },
    onResetClick() {
      this.isResetting = true;
      return axios
        .post(this.propsSource.resetPath)
        .then(() => {
          refreshCurrentPage();
        })
        .catch((error) => {
          this.$toast.show(I18N_DEFAULT_ERROR_MESSAGE);
          Sentry.captureException(error);
        })
        .finally(() => {
          this.isResetting = false;
        });
    },
    getFormData() {
      return new FormData(this.form());
    },
    onToggleIntegrationState(integrationActive) {
      this.integrationActive = integrationActive;
    },
    onRequestJiraIssueTypes() {
      this.requestJiraIssueTypes(this.getFormData());
    },
  },
  helpHtmlConfig: {
    ADD_TAGS: ['use'], // to support icon SVGs
    FORBID_ATTR: [], // This is trusted input so we can override the default config to allow data-* attributes
  },
  csrf,
  slackUpgradeInfo: {
    title: s__(
      `SlackIntegration|Update to the latest version of GitLab for Slack to get notifications`,
    ),
    text: s__(
      `SlackIntegration|Update to the latest version to receive notifications from GitLab.`,
    ),
    btnText: s__('SlackIntegration|Update to the latest version'),
  },
};
</script>

<template>
  <gl-form
    ref="integrationForm"
    method="post"
    class="gl-show-field-errors"
    data-testid="integration-settings-form"
    :action="propsSource.formPath"
    :novalidate="!integrationActive"
  >
    <input type="hidden" name="_method" value="put" />
    <input type="hidden" name="authenticity_token" :value="$options.csrf.token" />
    <input
      type="hidden"
      name="redirect_to"
      :value="propsSource.redirectTo"
      data-testid="redirect-to-field"
    />

    <div v-if="shouldUpgradeSlack" class="gl-mb-6">
      <gl-alert
        :dismissible="false"
        :title="$options.slackUpgradeInfo.title"
        :primary-button-link="customState.upgradeSlackUrl"
        :primary-button-text="$options.slackUpgradeInfo.btnText"
        class="gl-mb-5"
        >{{ $options.slackUpgradeInfo.text }}</gl-alert
      >
    </div>

    <override-dropdown
      v-if="defaultState !== null"
      :inherit-from-id="defaultState.id"
      :override="override"
      :learn-more-path="propsSource.learnMorePath"
      @change="setOverride"
    />

    <!-- helpHtml is trusted input -->
    <section v-if="showHelpHtml" class="gl-mb-6">
      <!-- helpHtml is trusted input -->
      <div v-safe-html:[$options.helpHtmlConfig]="helpHtml" data-testid="help-html"></div>
    </section>

    <section v-if="!hasSections">
      <active-checkbox
        v-if="propsSource.manualActivation"
        :key="`${currentKey}-active-checkbox`"
        @toggle-integration-active="onToggleIntegrationState"
      />
      <trigger-fields
        v-if="propsSource.triggerEvents.length"
        :key="`${currentKey}-trigger-fields`"
        :events="propsSource.triggerEvents"
        :type="propsSource.type"
      />
    </section>

    <template v-if="hasSections">
      <integration-form-section
        v-for="section in customState.sections"
        :key="section.type"
        :section="section"
        :is-validated="isValidated"
        @toggle-integration-active="onToggleIntegrationState"
        @request-jira-issue-types="onRequestJiraIssueTypes"
      />
    </template>

    <section v-if="hasFieldsWithoutSection">
      <dynamic-field
        v-for="field in fieldsWithoutSection"
        :key="`${currentKey}-${field.name}`"
        v-bind="field"
        :is-validated="isValidated"
        :data-testid="`${field.name}-div`"
      />
    </section>

    <integration-form-actions
      v-if="isEditable"
      :has-sections="hasSections"
      :is-saving="isSaving"
      :is-testing="isTesting"
      :is-resetting="isResetting"
      @save="onSaveClick"
      @test="onTestClick"
      @reset="onResetClick"
    />
  </gl-form>
</template>
