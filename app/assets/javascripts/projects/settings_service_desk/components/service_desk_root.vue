<script>
import { GlAlert, GlSprintf, GlLink } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import axios from '~/lib/utils/axios_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, sprintf } from '~/locale';
import ServiceDeskSetting from './service_desk_setting.vue';

const CustomEmailWrapper = () => import('./custom_email_wrapper.vue');

export default {
  serviceDeskEmailHelpPath: helpPagePath('/user/project/service_desk/configure.html', {
    anchor: 'use-an-additional-service-desk-alias-email',
  }),
  components: {
    GlAlert,
    GlSprintf,
    GlLink,
    ServiceDeskSetting,
    CustomEmailWrapper,
  },
  directives: {
    SafeHtml,
  },
  inject: {
    initialIsEnabled: {
      default: false,
    },
    isIssueTrackerEnabled: {
      default: false,
    },
    endpoint: {
      default: '',
    },
    initialIncomingEmail: {
      default: '',
    },
    serviceDeskEmail: {
      default: '',
    },
    serviceDeskEmailEnabled: {
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
    areTicketsConfidentialByDefault: {
      default: false,
    },
    reopenIssueOnExternalParticipantNote: {
      default: false,
    },
    addExternalParticipantsFromCc: {
      default: false,
    },
    templates: {
      default: [],
    },
    publicProject: {
      default: false,
    },
    customEmailEndpoint: {
      default: '',
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
      updatedServiceDeskEmail: this.serviceDeskEmail,
    };
  },
  computed: {
    showCustomEmailWrapper() {
      return this.isEnabled && this.isIssueTrackerEnabled;
    },
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

    onSaveTemplate({
      selectedTemplate,
      fileTemplateProjectId,
      outgoingName,
      projectKey,
      areTicketsConfidentialByDefault,
      reopenIssueOnExternalParticipantNote,
      addExternalParticipantsFromCc,
    }) {
      this.isTemplateSaving = true;

      const body = {
        issue_template_key: selectedTemplate,
        outgoing_name: outgoingName,
        project_key: projectKey,
        tickets_confidential_by_default: areTicketsConfidentialByDefault,
        reopen_issue_on_external_participant_note: reopenIssueOnExternalParticipantNote,
        add_external_participants_from_cc: addExternalParticipantsFromCc,
        service_desk_enabled: this.isEnabled,
        file_template_project_id: fileTemplateProjectId,
      };

      return axios
        .put(this.endpoint, body)
        .then(({ data }) => {
          this.updatedServiceDeskEmail = data?.service_desk_address;
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
          <gl-link :href="$options.serviceDeskEmailHelpPath" target="_blank">
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
      :is-issue-tracker-enabled="isIssueTrackerEnabled"
      :incoming-email="incomingEmail"
      :service-desk-email="updatedServiceDeskEmail"
      :service-desk-email-enabled="serviceDeskEmailEnabled"
      :initial-selected-template="selectedTemplate"
      :initial-selected-file-template-project-id="selectedFileTemplateProjectId"
      :initial-outgoing-name="outgoingName"
      :initial-project-key="projectKey"
      :initial-are-tickets-confidential-by-default="areTicketsConfidentialByDefault"
      :initial-reopen-issue-on-external-participant-note="reopenIssueOnExternalParticipantNote"
      :initial-add-external-participants-from-cc="addExternalParticipantsFromCc"
      :public-project="publicProject"
      :templates="templates"
      :is-template-saving="isTemplateSaving"
      @save="onSaveTemplate"
      @toggle="onEnableToggled"
    />
    <custom-email-wrapper
      v-if="showCustomEmailWrapper"
      :incoming-email="incomingEmail"
      :custom-email-endpoint="customEmailEndpoint"
    />
  </div>
</template>
