<script>
import { GlAlert, GlSafeHtmlDirective } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { __, sprintf } from '~/locale';
import ServiceDeskSetting from './service_desk_setting.vue';

export default {
  components: {
    GlAlert,
    ServiceDeskSetting,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  inject: {
    initialIsEnabled: {
      default: false,
    },
    endpoint: {
      default: '',
    },
    initialIncomingEmail: {
      default: '',
    },
    customEmail: {
      default: '',
    },
    customEmailEnabled: {
      default: false,
    },
    selectedTemplate: {
      default: '',
    },
    outgoingName: {
      default: '',
    },
    projectKey: {
      default: '',
    },
    templates: {
      default: [],
    },
  },
  data() {
    return {
      isEnabled: this.initialIsEnabled,
      isTemplateSaving: false,
      isAlertShowing: false,
      alertVariant: 'danger',
      alertMessage: '',
      incomingEmail: this.initialIncomingEmail,
      updatedCustomEmail: this.customEmail,
    };
  },
  methods: {
    onEnableToggled(isChecked) {
      this.isEnabled = isChecked;
      this.incomingEmail = '';

      const body = {
        service_desk_enabled: isChecked,
      };

      return axios
        .put(this.endpoint, body)
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

      const body = {
        issue_template_key: selectedTemplate,
        outgoing_name: outgoingName,
        project_key: projectKey,
        service_desk_enabled: this.isEnabled,
      };

      return axios
        .put(this.endpoint, body)
        .then(({ data }) => {
          this.updatedCustomEmail = data?.service_desk_address;
          this.showAlert(__('Changes saved.'), 'success');
        })
        .catch((err) => {
          this.showAlert(
            sprintf(__('An error occurred while saving changes: %{error}'), {
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
      <span v-safe-html="alertMessage"></span>
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
      @save="onSaveTemplate"
      @toggle="onEnableToggled"
    />
  </div>
</template>
