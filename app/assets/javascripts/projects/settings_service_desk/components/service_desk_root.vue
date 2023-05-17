<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import axios from '~/lib/utils/axios_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, sprintf } from '~/locale';
import ServiceDeskSetting from './service_desk_setting.vue';

export default {
  customEmailHelpPath: helpPagePath('/user/project/service_desk.html', {
    anchor: 'use-a-custom-email-address',
  }),
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    ServiceDeskSetting,
  },
  directives: {
    SafeHtml,
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
    selectedFileTemplateProjectId: {
      default: null,
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
    publicProject: {
      default: false,
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

    onSaveTemplate({ selectedTemplate, fileTemplateProjectId, outgoingName, projectKey }) {
      this.isTemplateSaving = true;

      const body = {
        issue_template_key: selectedTemplate,
        outgoing_name: outgoingName,
        project_key: projectKey,
        service_desk_enabled: this.isEnabled,
        file_template_project_id: fileTemplateProjectId,
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
    <gl-alert
      v-if="publicProject && isEnabled"
      class="mb-3"
      variant="warning"
      data-testid="public-project-alert"
      :dismissible="false"
    >
      <gl-sprintf
        :message="
          __(
            'This project is public. Non-members can guess the Service Desk email address, because it contains the group and project name. %{linkStart}How do I create a custom email address?%{linkEnd}',
          )
        "
      >
        <template #link="{ content }">
          <gl-link :href="$options.customEmailHelpPath" target="_blank">
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-alert v-if="isAlertShowing" class="mb-3" :variant="alertVariant" @dismiss="onDismiss">
      <span v-safe-html="alertMessage"></span>
    </gl-alert>
    <service-desk-setting
      :is-enabled="isEnabled"
      :incoming-email="incomingEmail"
      :custom-email="updatedCustomEmail"
      :custom-email-enabled="customEmailEnabled"
      :initial-selected-template="selectedTemplate"
      :initial-selected-file-template-project-id="selectedFileTemplateProjectId"
      :initial-outgoing-name="outgoingName"
      :initial-project-key="projectKey"
      :templates="templates"
      :is-template-saving="isTemplateSaving"
      @save="onSaveTemplate"
      @toggle="onEnableToggled"
    />
  </div>
</template>
