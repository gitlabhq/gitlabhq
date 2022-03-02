<script>
import { GlButton, GlModalDirective, GlSafeHtmlDirective as SafeHtml, GlForm } from '@gitlab/ui';
import axios from 'axios';
import * as Sentry from '@sentry/browser';
import { mapState, mapActions, mapGetters } from 'vuex';

import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
  I18N_DEFAULT_ERROR_MESSAGE,
  I18N_SUCCESSFUL_CONNECTION_MESSAGE,
  integrationLevels,
} from '~/integrations/constants';
import { refreshCurrentPage } from '~/lib/utils/url_utility';
import csrf from '~/lib/utils/csrf';
import { testIntegrationSettings } from '../api';
import ActiveCheckbox from './active_checkbox.vue';
import ConfirmationModal from './confirmation_modal.vue';
import DynamicField from './dynamic_field.vue';
import JiraIssuesFields from './jira_issues_fields.vue';
import JiraTriggerFields from './jira_trigger_fields.vue';
import OverrideDropdown from './override_dropdown.vue';
import ResetConfirmationModal from './reset_confirmation_modal.vue';
import TriggerFields from './trigger_fields.vue';

export default {
  name: 'IntegrationForm',
  components: {
    OverrideDropdown,
    ActiveCheckbox,
    JiraTriggerFields,
    JiraIssuesFields,
    TriggerFields,
    DynamicField,
    ConfirmationModal,
    ResetConfirmationModal,
    GlButton,
    GlForm,
  },
  directives: {
    GlModal: GlModalDirective,
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
      isTesting: false,
      isSaving: false,
      isResetting: false,
      isValidated: false,
    };
  },
  computed: {
    ...mapGetters(['currentKey', 'propsSource']),
    ...mapState(['defaultState', 'customState', 'override']),
    isEditable() {
      return this.propsSource.editable;
    },
    isJira() {
      return this.propsSource.type === 'jira';
    },
    isInstanceOrGroupLevel() {
      return (
        this.customState.integrationLevel === integrationLevels.INSTANCE ||
        this.customState.integrationLevel === integrationLevels.GROUP
      );
    },
    showResetButton() {
      return this.isInstanceOrGroupLevel && this.propsSource.resetPath;
    },
    showTestButton() {
      return this.propsSource.canTest;
    },
    disableButtons() {
      return Boolean(this.isSaving || this.isResetting || this.isTesting);
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
        .then(({ data: { error, message = I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE } }) => {
          if (error) {
            this.setIsValidated();
            this.$toast.show(message);
            return;
          }

          this.$toast.show(I18N_SUCCESSFUL_CONNECTION_MESSAGE);
        })
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
    ADD_ATTR: ['target'], // allow external links, can be removed after https://gitlab.com/gitlab-org/gitlab-ui/-/issues/1427 is implemented
    ADD_TAGS: ['use'], // to support icon SVGs
    FORBID_ATTR: [], // This is trusted input so we can override the default config to allow data-* attributes
  },
  csrf,
};
</script>

<template>
  <gl-form
    ref="integrationForm"
    method="post"
    class="gl-mb-3 gl-show-field-errors integration-settings-form"
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

    <div class="row">
      <div class="col-lg-4"></div>

      <div class="col-lg-8">
        <!-- helpHtml is trusted input -->
        <div v-if="helpHtml" v-safe-html:[$options.helpHtmlConfig]="helpHtml"></div>

        <active-checkbox
          v-if="propsSource.showActive"
          :key="`${currentKey}-active-checkbox`"
          @toggle-integration-active="onToggleIntegrationState"
        />
        <jira-trigger-fields
          v-if="isJira"
          :key="`${currentKey}-jira-trigger-fields`"
          v-bind="propsSource.triggerFieldsProps"
          :is-validated="isValidated"
        />
        <trigger-fields
          v-else-if="propsSource.triggerEvents.length"
          :key="`${currentKey}-trigger-fields`"
          :events="propsSource.triggerEvents"
          :type="propsSource.type"
        />
        <dynamic-field
          v-for="field in propsSource.fields"
          :key="`${currentKey}-${field.name}`"
          v-bind="field"
          :is-validated="isValidated"
        />
        <jira-issues-fields
          v-if="isJira && !isInstanceOrGroupLevel"
          :key="`${currentKey}-jira-issues-fields`"
          v-bind="propsSource.jiraIssuesProps"
          :is-validated="isValidated"
          @request-jira-issue-types="onRequestJiraIssueTypes"
        />

        <div
          v-if="isEditable"
          class="footer-block row-content-block gl-display-flex gl-justify-content-space-between"
        >
          <div>
            <template v-if="isInstanceOrGroupLevel">
              <gl-button
                v-gl-modal.confirmSaveIntegration
                category="primary"
                variant="confirm"
                :loading="isSaving"
                :disabled="disableButtons"
                data-testid="save-button-instance-group"
                data-qa-selector="save_changes_button"
              >
                {{ __('Save changes') }}
              </gl-button>
              <confirmation-modal @submit="onSaveClick" />
            </template>
            <gl-button
              v-else
              category="primary"
              variant="confirm"
              type="submit"
              :loading="isSaving"
              :disabled="disableButtons"
              data-testid="save-button"
              data-qa-selector="save_changes_button"
              @click.prevent="onSaveClick"
            >
              {{ __('Save changes') }}
            </gl-button>

            <gl-button
              v-if="showTestButton"
              category="secondary"
              variant="confirm"
              :loading="isTesting"
              :disabled="disableButtons"
              data-testid="test-button"
              @click.prevent="onTestClick"
            >
              {{ __('Test settings') }}
            </gl-button>

            <gl-button :href="propsSource.cancelPath">{{ __('Cancel') }}</gl-button>
          </div>

          <template v-if="showResetButton">
            <gl-button
              v-gl-modal.confirmResetIntegration
              category="tertiary"
              variant="danger"
              :loading="isResetting"
              :disabled="disableButtons"
              data-testid="reset-button"
            >
              {{ __('Reset') }}
            </gl-button>

            <reset-confirmation-modal @reset="onResetClick" />
          </template>
        </div>
      </div>
    </div>
  </gl-form>
</template>
