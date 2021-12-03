import { delay } from 'lodash';
import toast from '~/vue_shared/plugins/global_toast';
import initForm from './edit';
import eventHub from './edit/event_hub';
import {
  TEST_INTEGRATION_EVENT,
  SAVE_INTEGRATION_EVENT,
  TOGGLE_INTEGRATION_EVENT,
  VALIDATE_INTEGRATION_FORM_EVENT,
  I18N_DEFAULT_ERROR_MESSAGE,
  I18N_SUCCESSFUL_CONNECTION_MESSAGE,
} from './constants';
import { testIntegrationSettings } from './edit/api';

export default class IntegrationSettingsForm {
  constructor(formSelector) {
    this.$form = document.querySelector(formSelector);
    this.formActive = false;

    this.vue = null;

    // Form Metadata
    this.testEndPoint = this.$form.dataset.testUrl;
  }

  init() {
    // Init Vue component
    this.vue = initForm(
      document.querySelector('.js-vue-integration-settings'),
      document.querySelector('.js-vue-default-integration-settings'),
    );
    eventHub.$on(TOGGLE_INTEGRATION_EVENT, (active) => {
      this.formActive = active;
      this.toggleServiceState();
    });
    eventHub.$on(TEST_INTEGRATION_EVENT, () => {
      this.testIntegration();
    });
    eventHub.$on(SAVE_INTEGRATION_EVENT, () => {
      this.saveIntegration();
    });
  }

  saveIntegration() {
    // Save Service if not active and check the following if active;
    // 1) If form contents are valid
    // 2) If this service can be saved
    // If both conditions are true, we override form submission
    // and save the service using provided configuration.
    const formValid = this.$form.checkValidity() || this.formActive === false;

    if (formValid) {
      delay(() => {
        this.$form.submit();
      }, 100);
    } else {
      eventHub.$emit(VALIDATE_INTEGRATION_FORM_EVENT);
      this.vue.$store.dispatch('setIsSaving', false);
    }
  }

  testIntegration() {
    // Service was marked active so now we check;
    // 1) If form contents are valid
    // 2) If this service can be tested
    // If both conditions are true, we override form submission
    // and test the service using provided configuration.
    if (this.$form.checkValidity()) {
      this.testSettings(new FormData(this.$form));
    } else {
      eventHub.$emit(VALIDATE_INTEGRATION_FORM_EVENT);
      this.vue.$store.dispatch('setIsTesting', false);
    }
  }

  /**
   * Change Form's validation enforcement based on service status (active/inactive)
   */
  toggleServiceState() {
    if (this.formActive) {
      this.$form.removeAttribute('novalidate');
    } else if (!this.$form.getAttribute('novalidate')) {
      this.$form.setAttribute('novalidate', 'novalidate');
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
