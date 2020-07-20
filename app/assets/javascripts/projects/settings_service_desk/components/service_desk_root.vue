<script>
import { GlAlert } from '@gitlab/ui';
import { __ } from '~/locale';
import ServiceDeskSetting from './service_desk_setting.vue';
import ServiceDeskService from '../services/service_desk_service';
import eventHub from '../event_hub';

export default {
  name: 'ServiceDeskRoot',
  components: {
    GlAlert,
    ServiceDeskSetting,
  },
  props: {
    initialIsEnabled: {
      type: Boolean,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    initialIncomingEmail: {
      type: String,
      required: false,
      default: '',
    },
    selectedTemplate: {
      type: String,
      required: false,
      default: '',
    },
    outgoingName: {
      type: String,
      required: false,
      default: '',
    },
    projectKey: {
      type: String,
      required: false,
      default: '',
    },
    templates: {
      type: Array,
      required: false,
      default: () => [],
    },
  },

  data() {
    return {
      isEnabled: this.initialIsEnabled,
      incomingEmail: this.initialIncomingEmail,
      isTemplateSaving: false,
      isAlertShowing: false,
      alertVariant: 'danger',
      alertMessage: '',
    };
  },

  created() {
    eventHub.$on('serviceDeskEnabledCheckboxToggled', this.onEnableToggled);
    eventHub.$on('serviceDeskTemplateSave', this.onSaveTemplate);

    this.service = new ServiceDeskService(this.endpoint);

    if (this.isEnabled && !this.incomingEmail) {
      this.fetchIncomingEmail();
    }
  },

  beforeDestroy() {
    eventHub.$off('serviceDeskEnabledCheckboxToggled', this.onEnableToggled);
    eventHub.$off('serviceDeskTemplateSave', this.onSaveTemplate);
  },

  methods: {
    fetchIncomingEmail() {
      this.service
        .fetchIncomingEmail()
        .then(({ data }) => {
          const email = data.service_desk_address;
          if (!email) {
            throw new Error(__("Response didn't include `service_desk_address`"));
          }

          this.incomingEmail = email;
        })
        .catch(() =>
          this.showAlert(__('An error occurred while fetching the Service Desk address.')),
        );
    },

    onEnableToggled(isChecked) {
      this.isEnabled = isChecked;
      this.incomingEmail = '';

      this.service
        .toggleServiceDesk(isChecked)
        .then(({ data }) => {
          const email = data.service_desk_address;
          if (isChecked && !email) {
            throw new Error(__("Response didn't include `service_desk_address`"));
          }

          this.incomingEmail = email;
        })
        .catch(() => {
          const message = isChecked
            ? __('An error occurred while enabling Service Desk.')
            : __('An error occurred while disabling Service Desk.');

          this.showAlert(message);
        });
    },

    onSaveTemplate({ selectedTemplate, outgoingName, projectKey }) {
      this.isTemplateSaving = true;
      this.service
        .updateTemplate({ selectedTemplate, outgoingName, projectKey }, this.isEnabled)
        .then(() => this.showAlert(__('Template was successfully saved.'), 'success'))
        .catch(() =>
          this.showAlert(
            __('An error occurred while saving the template. Please check if the template exists.'),
          ),
        )
        .finally(() => {
          this.isTemplateSaving = false;
        });
    },

    showAlert(message, variant = 'danger') {
      this.isAlertShowing = true;
      this.alertMessage = message;
      this.alertVariant = variant;
    },

    onDismiss() {
      this.isAlertShowing = false;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="isAlertShowing" class="mb-3" :variant="alertVariant" @dismiss="onDismiss">
      {{ alertMessage }}
    </gl-alert>
    <service-desk-setting
      :is-enabled="isEnabled"
      :incoming-email="incomingEmail"
      :initial-selected-template="selectedTemplate"
      :initial-outgoing-name="outgoingName"
      :initial-project-key="projectKey"
      :templates="templates"
      :is-template-saving="isTemplateSaving"
    />
  </div>
</template>
