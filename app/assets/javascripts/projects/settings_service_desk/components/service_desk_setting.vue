<script>
import {
  GlButton,
  GlToggle,
  GlLoadingIcon,
  GlSprintf,
  GlFormCheckbox,
  GlFormInputGroup,
  GlFormGroup,
  GlFormInput,
  GlLink,
  GlAlert,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { __, s__ } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ServiceDeskTemplateDropdown from './service_desk_template_dropdown.vue';

export default {
  i18n: {
    toggleLabel: __('Activate Service Desk'),
    issueTrackerEnableMessage: __(
      'To use Service Desk in this project, you must %{linkStart}activate the issue tracker%{linkEnd}.',
    ),
    reopenIssueOnExternalParticipantNote: {
      label: s__('ServiceDesk|Reopen issues when an external participant comments'),
      help: s__(
        'ServiceDesk|This also adds an internal comment that mentions the assignees of the issue.',
      ),
    },
    addExternalParticipantsFromCc: {
      label: s__('ServiceDesk|Add external participants from the %{codeStart}Cc%{codeEnd} header'),
      help: s__(
        'ServiceDesk|Add email addresses in the %{codeStart}Cc%{codeEnd} header of Service Desk emails to the issue.',
      ),
      helpNotificationExtra: s__(
        'ServiceDesk|Like the author, external participants receive Service Desk emails and can participate in the discussion.',
      ),
    },
  },
  components: {
    ClipboardButton,
    GlButton,
    GlToggle,
    GlLoadingIcon,
    GlFormCheckbox,
    GlSprintf,
    GlFormInput,
    GlFormGroup,
    GlFormInputGroup,
    GlLink,
    GlAlert,
    ServiceDeskTemplateDropdown,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    isEnabled: {
      type: Boolean,
      required: true,
    },
    isIssueTrackerEnabled: {
      type: Boolean,
      required: true,
    },
    incomingEmail: {
      type: String,
      required: false,
      default: '',
    },
    serviceDeskEmail: {
      type: String,
      required: false,
      default: '',
    },
    serviceDeskEmailEnabled: {
      type: Boolean,
      required: false,
    },
    initialSelectedTemplate: {
      type: String,
      required: false,
      default: '',
    },
    initialSelectedFileTemplateProjectId: {
      type: Number,
      required: false,
      default: null,
    },
    initialOutgoingName: {
      type: String,
      required: false,
      default: '',
    },
    initialProjectKey: {
      type: String,
      required: false,
      default: '',
    },
    initialReopenIssueOnExternalParticipantNote: {
      type: Boolean,
      required: false,
      default: false,
    },
    initialAddExternalParticipantsFromCc: {
      type: Boolean,
      required: false,
      default: false,
    },
    templates: {
      type: Array,
      required: false,
      default: () => [],
    },
    isTemplateSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      selectedTemplate: this.initialSelectedTemplate,
      selectedFileTemplateProjectId: this.initialSelectedFileTemplateProjectId,
      outgoingName: this.initialOutgoingName || __('GitLab Support Bot'),
      projectKey: this.initialProjectKey,
      reopenIssueOnExternalParticipantNote: this.initialReopenIssueOnExternalParticipantNote,
      addExternalParticipantsFromCc: this.initialAddExternalParticipantsFromCc,
      searchTerm: '',
      projectKeyError: null,
    };
  },
  computed: {
    showAddExternalParticipantsFromCC() {
      return this.glFeatures.issueEmailParticipants;
    },
    hasProjectKeySupport() {
      return Boolean(this.serviceDeskEmailEnabled);
    },
    email() {
      return this.serviceDeskEmail || this.incomingEmail;
    },
    hasServiceDeskEmail() {
      return this.serviceDeskEmail && this.serviceDeskEmail !== this.incomingEmail;
    },
    emailSuffixHelpUrl() {
      return helpPagePath('user/project/service_desk/configure.html', {
        anchor: 'configure-a-suffix-for-service-desk-alias-email',
      });
    },
    serviceDeskEmailAddressHelpUrl() {
      return helpPagePath('user/project/service_desk/configure.html', {
        anchor: 'use-an-additional-service-desk-alias-email',
      });
    },
    issuesHelpPagePath() {
      return helpPagePath('user/project/settings/index.md', {
        anchor: 'configure-project-visibility-features-and-permissions',
      });
    },
  },
  methods: {
    onCheckboxToggle(isChecked) {
      this.$emit('toggle', isChecked);
    },
    onSaveTemplate() {
      this.$emit('save', {
        selectedTemplate: this.selectedTemplate,
        outgoingName: this.outgoingName,
        projectKey: this.projectKey,
        reopenIssueOnExternalParticipantNote: this.reopenIssueOnExternalParticipantNote,
        addExternalParticipantsFromCc: this.addExternalParticipantsFromCc,
        fileTemplateProjectId: this.selectedFileTemplateProjectId,
      });
    },
    templateChange({ selectedFileTemplateProjectId, selectedTemplate }) {
      this.selectedFileTemplateProjectId = selectedFileTemplateProjectId;
      this.selectedTemplate = selectedTemplate;
    },
    validateProjectKey() {
      if (this.projectKey && !/^[a-z0-9_]+$/.test(this.projectKey)) {
        this.projectKeyError = __('Only use lowercase letters, numbers, and underscores.');
        return;
      }

      this.projectKeyError = null;
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="!isIssueTrackerEnabled" class="mb-3" variant="info" :dismissible="false">
      <gl-sprintf :message="$options.i18n.issueTrackerEnableMessage">
        <template #link="{ content }">
          <gl-link
            class="gl-display-inline-block"
            data-testid="issue-help-page"
            :href="issuesHelpPagePath"
            target="_blank"
          >
            {{ content }}
          </gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>
    <gl-toggle
      id="service-desk-checkbox"
      :value="isEnabled"
      :disabled="!isIssueTrackerEnabled"
      class="d-inline-block align-middle mr-1"
      :label="$options.i18n.toggleLabel"
      label-position="hidden"
      @change="onCheckboxToggle"
    />
    <label class="align-middle">
      {{ $options.i18n.toggleLabel }}
    </label>
    <div v-if="isEnabled" class="row mt-3">
      <div class="col-md-9 mb-0">
        <gl-form-group
          :label="__('Email address to use for Service Desk')"
          label-for="incoming-email"
          data-testid="incoming-email-label"
        >
          <gl-form-input-group v-if="email">
            <gl-form-input
              id="incoming-email"
              ref="service-desk-incoming-email"
              type="text"
              data-testid="incoming-email"
              :placeholder="__('Incoming email')"
              :aria-label="__('Incoming email')"
              aria-describedby="incoming-email-describer"
              :value="email"
              :disabled="true"
            />
            <template #append>
              <clipboard-button :title="__('Copy')" :text="email" css-class="input-group-text" />
            </template>
          </gl-form-input-group>
          <template v-if="email && hasServiceDeskEmail" #description>
            <span class="gl-mt-2 gl-display-inline-block">
              <gl-sprintf :message="__('Emails sent to %{email} are also supported.')">
                <template #email>
                  <code>{{ incomingEmail }}</code>
                </template>
              </gl-sprintf>
            </span>
          </template>
          <template v-if="!email">
            <gl-loading-icon size="sm" :inline="true" />
            <span class="sr-only">{{ __('Fetching incoming email') }}</span>
          </template>
        </gl-form-group>

        <gl-form-group
          :label="__('Email address suffix')"
          :state="!projectKeyError"
          data-testid="suffix-form-group"
          :disabled="!isIssueTrackerEnabled"
        >
          <gl-form-input
            v-if="hasProjectKeySupport"
            id="service-desk-project-suffix"
            v-model.trim="projectKey"
            data-testid="project-suffix"
            @blur="validateProjectKey"
          />

          <template v-if="hasProjectKeySupport" #description>
            <gl-sprintf
              :message="
                __('Add a suffix to Service Desk email address. %{linkStart}Learn more%{linkEnd}.')
              "
            >
              <template #link="{ content }">
                <gl-link :href="emailSuffixHelpUrl" target="_blank">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </template>
          <template v-else #description>
            <span class="gl-text-gray-900">
              <gl-sprintf
                :message="
                  __(
                    'To add a custom suffix, set up a Service Desk email address. %{linkStart}Learn more%{linkEnd}.',
                  )
                "
              >
                <template #link="{ content }">
                  <gl-link :href="serviceDeskEmailAddressHelpUrl" target="_blank">{{
                    content
                  }}</gl-link>
                </template>
              </gl-sprintf>
            </span>
          </template>

          <template v-if="hasProjectKeySupport && projectKeyError" #invalid-feedback>
            {{ projectKeyError }}
          </template>
        </gl-form-group>

        <gl-form-group
          :label="__('Template to append to all Service Desk issues')"
          :state="!projectKeyError"
          class="mt-3"
          :disabled="!isIssueTrackerEnabled"
        >
          <service-desk-template-dropdown
            :selected-template="selectedTemplate"
            :selected-file-template-project-id="selectedFileTemplateProjectId"
            :templates="templates"
            @change="templateChange"
          />
        </gl-form-group>

        <gl-form-group
          :label="__('Email display name')"
          label-for="service-desk-email-from-name"
          :state="!projectKeyError"
          class="mt-3"
        >
          <gl-form-input
            id="service-desk-email-from-name"
            v-model.trim="outgoingName"
            data-testid="email-from-name"
            :disabled="!isIssueTrackerEnabled"
          />

          <template #description>
            {{ __('Name to be used as the sender for emails from Service Desk.') }}
          </template>
        </gl-form-group>

        <gl-form-checkbox
          v-model="reopenIssueOnExternalParticipantNote"
          :disabled="!isIssueTrackerEnabled"
          data-testid="reopen-issue-on-external-participant-note"
        >
          {{ $options.i18n.reopenIssueOnExternalParticipantNote.label }}

          <template #help>
            {{ $options.i18n.reopenIssueOnExternalParticipantNote.help }}
          </template>
        </gl-form-checkbox>

        <gl-form-checkbox
          v-if="showAddExternalParticipantsFromCC"
          v-model="addExternalParticipantsFromCc"
          :disabled="!isIssueTrackerEnabled"
          data-testid="add-external-participants-from-cc"
        >
          <gl-sprintf :message="$options.i18n.addExternalParticipantsFromCc.label">
            <template #code="{ content }">
              <code>{{ content }}</code>
            </template>
          </gl-sprintf>

          <template #help>
            <gl-sprintf :message="$options.i18n.addExternalParticipantsFromCc.help">
              <template #code="{ content }">
                <code>{{ content }}</code>
              </template>
            </gl-sprintf>
            {{ $options.i18n.addExternalParticipantsFromCc.helpNotificationExtra }}
          </template>
        </gl-form-checkbox>

        <gl-button
          variant="confirm"
          class="gl-mt-5"
          data-testid="save_service_desk_settings_button"
          :disabled="isTemplateSaving || !isIssueTrackerEnabled"
          @click="onSaveTemplate"
        >
          {{ __('Save changes') }}
        </gl-button>
      </div>
    </div>
  </div>
</template>
