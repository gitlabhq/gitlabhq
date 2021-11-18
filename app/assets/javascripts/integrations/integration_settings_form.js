import { delay } from 'lodash';
import toast from '~/vue_shared/plugins/global_toast';
import axios from '../lib/utils/axios_utils';
import initForm from './edit';
import eventHub from './edit/event_hub';
import {
  TEST_INTEGRATION_EVENT,
  SAVE_INTEGRATION_EVENT,
  GET_JIRA_ISSUE_TYPES_EVENT,
  TOGGLE_INTEGRATION_EVENT,
  VALIDATE_INTEGRATION_FORM_EVENT,
  I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE,
  I18N_DEFAULT_ERROR_MESSAGE,
  I18N_SUCCESSFUL_CONNECTION_MESSAGE,
} from './constants';

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
    eventHub.$on(GET_JIRA_ISSUE_TYPES_EVENT, () => {
      this.getJiraIssueTypes(new FormData(this.$form));
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
  getJiraIssueTypes(formData) {
    const {
      $store: { dispatch },
    } = this.vue;

    dispatch('requestJiraIssueTypes');

    return this.fetchTestSettings(formData)
      .then(
        ({
          data: { issuetypes, error, message = I18N_FETCH_TEST_SETTINGS_DEFAULT_ERROR_MESSAGE },
        }) => {
          if (error || !issuetypes?.length) {
            eventHub.$emit(VALIDATE_INTEGRATION_FORM_EVENT);
            throw new Error(message);
          }

          dispatch('receiveJiraIssueTypesSuccess', issuetypes);
        },
      )
      .catch(({ message = I18N_DEFAULT_ERROR_MESSAGE }) => {
        dispatch('receiveJiraIssueTypesError', message);
      });
  }

  /**
   *  Send request to the test endpoint which checks if the current config is valid
   */
  fetchTestSettings(formData) {
    return axios.put(this.testEndPoint, formData);
  }

  /**
   * Test Integration config
   */
  testSettings(formData) {
    return this.fetchTestSettings(formData)
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
