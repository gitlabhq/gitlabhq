import { delay } from 'lodash';
import initForm from './edit';
import eventHub from './edit/event_hub';
import { SAVE_INTEGRATION_EVENT, VALIDATE_INTEGRATION_FORM_EVENT } from './constants';

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
}
