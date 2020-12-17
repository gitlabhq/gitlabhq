import $ from 'jquery';
import axios from '../lib/utils/axios_utils';
import { __, s__ } from '~/locale';
import toast from '~/vue_shared/plugins/global_toast';
import initForm from './edit';
import eventHub from './edit/event_hub';

export default class IntegrationSettingsForm {
  constructor(formSelector) {
    this.$form = $(formSelector);
    this.formActive = false;

    this.vue = null;

    // Form Metadata
    this.testEndPoint = this.$form.data('testUrl');
  }

  init() {
    // Init Vue component
    this.vue = initForm(
      document.querySelector('.js-vue-integration-settings'),
      document.querySelector('.js-vue-default-integration-settings'),
    );
    eventHub.$on('toggle', active => {
      this.formActive = active;
      this.toggleServiceState();
    });
    eventHub.$on('testIntegration', () => {
      this.testIntegration();
    });
    eventHub.$on('saveIntegration', () => {
      this.saveIntegration();
    });
  }

  saveIntegration() {
    // Save Service if not active and check the following if active;
    // 1) If form contents are valid
    // 2) If this service can be saved
    // If both conditions are true, we override form submission
    // and save the service using provided configuration.
    const formValid = this.$form.get(0).checkValidity() || this.formActive === false;

    if (formValid) {
      this.$form.submit();
    } else {
      eventHub.$emit('validateForm');
      this.vue.$store.dispatch('setIsSaving', false);
    }
  }

  testIntegration() {
    // Service was marked active so now we check;
    // 1) If form contents are valid
    // 2) If this service can be tested
    // If both conditions are true, we override form submission
    // and test the service using provided configuration.
    if (this.$form.get(0).checkValidity()) {
      // eslint-disable-next-line no-jquery/no-serialize
      this.testSettings(this.$form.serialize());
    } else {
      eventHub.$emit('validateForm');
      this.vue.$store.dispatch('setIsTesting', false);
    }
  }

  /**
   * Change Form's validation enforcement based on service status (active/inactive)
   */
  toggleServiceState() {
    if (this.formActive) {
      this.$form.removeAttr('novalidate');
    } else if (!this.$form.attr('novalidate')) {
      this.$form.attr('novalidate', 'novalidate');
    }
  }

  /**
   * Test Integration config
   */
  testSettings(formData) {
    return axios
      .put(this.testEndPoint, formData)
      .then(({ data }) => {
        if (data.error) {
          toast(`${data.message} ${data.service_response}`);
        } else {
          toast(s__('Integrations|Connection successful.'));
        }
      })
      .catch(() => {
        toast(__('Something went wrong on our end.'));
      })
      .finally(() => {
        this.vue.$store.dispatch('setIsTesting', false);
      });
  }
}
