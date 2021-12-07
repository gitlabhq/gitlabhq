import { delay } from 'lodash';
import toast from '~/vue_shared/plugins/global_toast';
import initForm from './edit';
import eventHub from './edit/event_hub';
import {
  TEST_INTEGRATION_EVENT,
  SAVE_INTEGRATION_EVENT,
  VALIDATE_INTEGRATION_FORM_EVENT,
  I18N_DEFAULT_ERROR_MESSAGE,
  I18N_SUCCESSFUL_CONNECTION_MESSAGE,
} from './constants';
import { testIntegrationSettings } from './edit/api';

export default class IntegrationSettingsForm {
  constructor(formSelector) {
    this.formSelector = formSelector;
    this.$form = document.querySelector(formSelector);

    this.vue = null;

    // Form Metadata
    this.testEndPoint = this.$form.dataset.testUrl;
  }

  init() {
    // Init Vue component
    this.vue = initForm(
      document.querySelector('.js-vue-integration-settings'),
      document.querySelector('.js-vue-default-integration-settings'),
      this.formSelector,
    );
    eventHub.$on(TEST_INTEGRATION_EVENT, (formValid) => {
      this.testIntegration(formValid);
    });
    eventHub.$on(SAVE_INTEGRATION_EVENT, (formValid) => {
      this.saveIntegration(formValid);
    });
  }

  saveIntegration(formValid) {
    // Save Service if not active and check the following if active;
    // 1) If form contents are valid
    // 2) If this service can be saved
    // If both conditions are true, we override form submission
    // and save the service using provided configuration.

    if (formValid) {
      delay(() => {
        this.$form.submit();
      }, 100);
    } else {
      eventHub.$emit(VALIDATE_INTEGRATION_FORM_EVENT);
      this.vue.$store.dispatch('setIsSaving', false);
    }
  }

  testIntegration(formValid) {
    // Service was marked active so now we check;
    // 1) If form contents are valid
    // 2) If this service can be tested
    // If both conditions are true, we override form submission
    // and test the service using provided configuration.
    if (formValid) {
      this.testSettings(new FormData(this.$form));
    } else {
      eventHub.$emit(VALIDATE_INTEGRATION_FORM_EVENT);
      this.vue.$store.dispatch('setIsTesting', false);
    }
  }

  /**
   * Get a list of Jira issue types for the currently configured project
   *
   * @param {string} formData - URL encoded string containing the form data
   *
   * @return {Promise}
   */

  /**
   * Test Integration config
   */
  testSettings(formData) {
    return testIntegrationSettings(this.testEndPoint, formData)
      .then(({ data }) => {
        if (data.error) {
          toast(`${data.message} ${data.service_response}`);
        } else {
          this.vue.$store.dispatch('receiveJiraIssueTypesSuccess', data.issuetypes);
          toast(I18N_SUCCESSFUL_CONNECTION_MESSAGE);
        }
      })
      .catch(() => {
        toast(I18N_DEFAULT_ERROR_MESSAGE);
      })
      .finally(() => {
        this.vue.$store.dispatch('setIsTesting', false);
      });
  }
}
