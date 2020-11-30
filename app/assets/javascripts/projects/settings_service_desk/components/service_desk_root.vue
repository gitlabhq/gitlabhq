<script>
import { GlAlert } from '@gitlab/ui';
import { __, sprintf } from '~/locale';
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
    incomingEmail: {
      type: String,
      required: false,
      default: '',
    },
    customEmail: {
      type: String,
      required: false,
      default: '',
    },
    customEmailEnabled: {
      type: Boolean,
      required: false,
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
      isTemplateSaving: false,
      isAlertShowing: false,
      alertVariant: 'danger',
      alertMessage: '',
      updatedCustomEmail: this.customEmail,
    };
  },

  created() {
    eventHub.$on('serviceDeskEnabledCheckboxToggled', this.onEnableToggled);
    eventHub.$on('serviceDeskTemplateSave', this.onSaveTemplate);
    this.service = new ServiceDeskService(this.endpoint);
  },

  beforeDestroy() {
    eventHub.$off('serviceDeskEnabledCheckboxToggled', this.onEnableToggled);
    eventHub.$off('serviceDeskTemplateSave', this.onSaveTemplate);
  },

  methods: {
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
        .then(({ data }) => {
          this.updatedCustomEmail = data?.service_desk_address;
          this.showAlert(__('Changes were successfully made.'), 'success');
        })
        .catch(err => {
          this.showAlert(
            sprintf(__('An error occured while making the changes: %{error}'), {
              error: err?.response?.data?.message,
            }),
          );
        })
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
      :custom-email="updatedCustomEmail"
      :custom-email-enabled="customEmailEnabled"
      :initial-selected-template="selectedTemplate"
      :initial-outgoing-name="outgoingName"
      :initial-project-key="projectKey"
      :templates="templates"
      :is-template-saving="isTemplateSaving"
    />
  </div>
</template>
