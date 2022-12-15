<script>
import { GlAlert, GlBadge, GlButton, GlForm } from '@gitlab/ui';
import axios from 'axios';
import * as Sentry from '@sentry/browser';
import { mapState, mapActions, mapGetters } from 'vuex';
import { s__ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import {
  I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
  I18N_DEFAULT_ERROR_MESSAGE,
  I18N_SUCCESSFUL_CONNECTION_MESSAGE,
  INTEGRATION_FORM_TYPE_SLACK,
  integrationFormSectionComponents,
  billingPlanNames,
} from '~/integrations/constants';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import csrf from '~/lib/utils/csrf';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { testIntegrationSettings } from '../api';
import ActiveCheckbox from './active_checkbox.vue';
import DynamicField from './dynamic_field.vue';
import OverrideDropdown from './override_dropdown.vue';
import TriggerFields from './trigger_fields.vue';
import IntegrationFormActions from './integration_form_actions.vue';

export default {
  name: 'IntegrationForm',
  components: {
    OverrideDropdown,
    ActiveCheckbox,
    TriggerFields,
    DynamicField,
    IntegrationFormActions,
    IntegrationSectionConfiguration: () =>
      import(
        /* webpackChunkName: 'integrationSectionConfiguration' */ '~/integrations/edit/components/sections/configuration.vue'
      ),
    IntegrationSectionConnection: () =>
      import(
        /* webpackChunkName: 'integrationSectionConnection' */ '~/integrations/edit/components/sections/connection.vue'
      ),
    IntegrationSectionJiraIssues: () =>
      import(
        /* webpackChunkName: 'integrationSectionJiraIssues' */ '~/integrations/edit/components/sections/jira_issues.vue'
      ),
    IntegrationSectionJiraTrigger: () =>
      import(
        /* webpackChunkName: 'integrationSectionJiraTrigger' */ '~/integrations/edit/components/sections/jira_trigger.vue'
      ),
    IntegrationSectionTrigger: () =>
      import(
        /* webpackChunkName: 'integrationSectionTrigger' */ '~/integrations/edit/components/sections/trigger.vue'
      ),
    GlAlert,
    GlBadge,
    GlButton,
    GlForm,
  },
  directives: {
    SafeHtml,
  },
  mixins: [glFeatureFlagsMixin()],
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
      if (this.hasSlackNotificationsDisabled) {
        return false;
      }
      return this.customState.sections.length !== 0;
    },
    fieldsWithoutSection() {
      return this.hasSections
        ? this.propsSource.fields.filter((field) => !field.section)
        : this.propsSource.fields;
    },
    hasFieldsWithoutSection() {
      if (this.hasSlackNotificationsDisabled) {
        return false;
      }
      return this.fieldsWithoutSection.length;
    },
    isSlackIntegration() {
      return this.propsSource.type === INTEGRATION_FORM_TYPE_SLACK;
    },
    hasSlackNotificationsDisabled() {
      return this.isSlackIntegration && !this.glFeatures.integrationSlackAppNotifications;
    },
    showHelpHtml() {
      if (this.isSlackIntegration) {
        return this.helpHtml;
      }
      return !this.hasSections && this.helpHtml;
    },
    shouldUpgradeSlack() {
      return (
        this.isSlackIntegration &&
        this.glFeatures.integrationSlackAppNotifications &&
        this.customState.shouldUpgradeSlack &&
        (this.hasFieldsWithoutSection || this.hasSections)
      );
    },
  },
  methods: {
    ...mapActions(['setOverride', 'requestJiraIssueTypes']),
    fieldsForSection(section) {
      return this.propsSource.fields.filter((field) => field.section === section.type);
    },
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
    onRequestJiraIssueTypes() {
      this.requestJiraIssueTypes(this.getFormData());
    },
    getFormData() {
      return new FormData(this.form());
    },
    onToggleIntegrationState(integrationActive) {
      this.integrationActive = integrationActive;
    },
  },
  helpHtmlConfig: {
    ADD_TAGS: ['use'], // to support icon SVGs
    FORBID_ATTR: [], // This is trusted input so we can override the default config to allow data-* attributes
  },
  csrf,
  integrationFormSectionComponents,
  billingPlanNames,
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
    class="gl-mt-6 gl-mb-3 gl-show-field-errors integration-settings-form"
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

    <override-dropdown
      v-if="defaultState !== null"
      :inherit-from-id="defaultState.id"
      :override="override"
      :learn-more-path="propsSource.learnMorePath"
      @change="setOverride"
    />

    <section v-if="showHelpHtml" class="gl-lg-display-flex gl-justify-content-end gl-mb-6">
      <!-- helpHtml is trusted input -->
      <div
        v-safe-html:[$options.helpHtmlConfig]="helpHtml"
        data-testid="help-html"
        class="gl-flex-basis-two-thirds"
      ></div>
    </section>

    <section v-if="!hasSections" class="gl-lg-display-flex gl-justify-content-end">
      <div class="gl-flex-basis-two-thirds">
        <active-checkbox
          v-if="propsSource.showActive"
          :key="`${currentKey}-active-checkbox`"
          @toggle-integration-active="onToggleIntegrationState"
        />
        <trigger-fields
          v-if="propsSource.triggerEvents.length"
          :key="`${currentKey}-trigger-fields`"
          :events="propsSource.triggerEvents"
          :type="propsSource.type"
        />
      </div>
    </section>

    <div v-if="shouldUpgradeSlack" class="gl-border-t">
      <gl-alert
        :dismissible="false"
        :title="$options.slackUpgradeInfo.title"
        :primary-button-link="customState.upgradeSlackUrl"
        :primary-button-text="$options.slackUpgradeInfo.btnText"
        class="gl-mb-8 gl-mt-5"
        >{{ $options.slackUpgradeInfo.text }}</gl-alert
      >
    </div>

    <template v-if="hasSections">
      <div
        v-for="(section, index) in customState.sections"
        :key="section.type"
        :class="{ 'gl-border-b gl-pb-3 gl-mb-6': index !== customState.sections.length - 1 }"
        data-testid="integration-section"
      >
        <section class="gl-lg-display-flex">
          <div class="gl-flex-basis-third gl-mr-4">
            <h4 class="gl-mt-0">
              {{ section.title
              }}<gl-badge
                v-if="section.plan"
                :href="propsSource.aboutPricingUrl"
                target="_blank"
                rel="noopener noreferrer"
                variant="tier"
                icon="license"
                class="gl-ml-3"
              >
                {{ $options.billingPlanNames[section.plan] }}
              </gl-badge>
            </h4>
            <p v-safe-html="section.description"></p>
          </div>

          <div class="gl-flex-basis-two-thirds">
            <component
              :is="$options.integrationFormSectionComponents[section.type]"
              :fields="fieldsForSection(section)"
              :is-validated="isValidated"
              @toggle-integration-active="onToggleIntegrationState"
              @request-jira-issue-types="onRequestJiraIssueTypes"
            />
          </div>
        </section>
      </div>
    </template>

    <section v-if="hasFieldsWithoutSection" class="gl-lg-display-flex gl-justify-content-end">
      <div class="gl-flex-basis-two-thirds">
        <dynamic-field
          v-for="field in fieldsWithoutSection"
          :key="`${currentKey}-${field.name}`"
          v-bind="field"
          :is-validated="isValidated"
          :data-qa-selector="`${field.name}_div`"
        />
      </div>
    </section>

    <integration-form-actions
      v-if="isEditable"
      :has-sections="hasSections"
      :class="{ 'gl-lg-display-flex gl-justify-content-end': !hasSections }"
      :is-saving="isSaving"
      :is-testing="isTesting"
      :is-resetting="isResetting"
      @save="onSaveClick"
      @test="onTestClick"
      @reset="onResetClick"
    />
  </gl-form>
</template>
