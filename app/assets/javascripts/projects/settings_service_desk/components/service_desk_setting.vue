<script>
import { GlButton, GlToggle, GlLoadingIcon, GlSprintf, GlFormInput, GlLink } from '@gitlab/ui';
import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ServiceDeskTemplateDropdown from './service_desk_template_dropdown.vue';

export default {
  i18n: {
    toggleLabel: __('Activate Service Desk'),
  },
  components: {
    ClipboardButton,
    GlButton,
    GlToggle,
    GlLoadingIcon,
    GlSprintf,
    GlFormInput,
    GlLink,
    ServiceDeskTemplateDropdown,
  },
  props: {
    isEnabled: {
      type: Boolean,
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
      searchTerm: '',
      projectKeyError: null,
    };
  },
  computed: {
    hasProjectKeySupport() {
      return Boolean(this.customEmailEnabled);
    },
    email() {
      return this.customEmail || this.incomingEmail;
    },
    hasCustomEmail() {
      return this.customEmail && this.customEmail !== this.incomingEmail;
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
        fileTemplateProjectId: this.selectedFileTemplateProjectId,
      });
    },
    templateChange({ selectedFileTemplateProjectId, selectedTemplate }) {
      this.selectedFileTemplateProjectId = selectedFileTemplateProjectId;
      this.selectedTemplate = selectedTemplate;
    },
    validateProjectKey() {
      if (this.projectKey && !new RegExp(/^[a-z0-9_]+$/).test(this.projectKey)) {
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
    <gl-toggle
      id="service-desk-checkbox"
      :value="isEnabled"
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
        <strong
          id="incoming-email-describer"
          class="gl-display-block gl-mb-1"
          data-testid="incoming-email-describer"
        >
          {{ __('Email address to use for Support Desk') }}
        </strong>
        <template v-if="email">
          <div class="input-group">
            <input
              ref="service-desk-incoming-email"
              type="text"
              class="form-control"
              data-testid="incoming-email"
              :placeholder="__('Incoming email')"
              :aria-label="__('Incoming email')"
              aria-describedby="incoming-email-describer"
              :value="email"
              disabled="true"
            />
            <div class="input-group-append">
              <clipboard-button :title="__('Copy')" :text="email" css-class="input-group-text" />
            </div>
          </div>
          <span v-if="hasCustomEmail" class="form-text text-muted">
            <gl-sprintf :message="__('Emails sent to %{email} are also supported.')">
              <template #email>
                <code>{{ incomingEmail }}</code>
              </template>
            </gl-sprintf>
          </span>
        </template>
        <template v-else>
          <gl-loading-icon size="sm" :inline="true" />
          <span class="sr-only">{{ __('Fetching incoming email') }}</span>
        </template>

        <label for="service-desk-project-suffix" class="mt-3">
          {{ __('Project name suffix') }}
        </label>
        <gl-form-input
          v-if="hasProjectKeySupport"
          id="service-desk-project-suffix"
          v-model.trim="projectKey"
          data-testid="project-suffix"
          class="form-control"
          :state="!projectKeyError"
          @blur="validateProjectKey"
        />
        <span v-if="hasProjectKeySupport && projectKeyError" class="form-text text-danger">
          {{ projectKeyError }}
        </span>
        <span
          v-if="hasProjectKeySupport"
          class="form-text text-muted"
          :class="{ 'gl-mt-2!': hasProjectKeySupport && projectKeyError }"
        >
          {{ __('A string appended to the project path to form the Service Desk email address.') }}
        </span>
        <span v-else class="form-text text-muted">
          <gl-sprintf
            :message="
              __(
                'To add a custom suffix, set up a Service Desk email address. %{linkStart}Learn more.%{linkEnd}',
              )
            "
          >
            <template #link="{ content }">
              <gl-link
                href="https://docs.gitlab.com/ee/user/project/service_desk.html#using-a-custom-email-address"
                target="_blank"
                class="gl-text-blue-600 font-size-inherit"
                >{{ content }}
              </gl-link>
            </template>
          </gl-sprintf>
        </span>

        <label for="service-desk-template-select" class="mt-3">
          {{ __('Template to append to all Service Desk issues') }}
        </label>
        <service-desk-template-dropdown
          :selected-template="selectedTemplate"
          :selected-file-template-project-id="selectedFileTemplateProjectId"
          :templates="templates"
          @change="templateChange"
        />

        <label for="service-desk-email-from-name" class="mt-3">
          {{ __('Email display name') }}
        </label>
        <input id="service-desk-email-from-name" v-model.trim="outgoingName" class="form-control" />
        <span class="form-text text-muted">
          {{ __('Emails sent from Service Desk have this name.') }}
        </span>
        <div class="gl-display-flex gl-justify-content-end">
          <gl-button
            variant="success"
            class="gl-mt-5"
            data-testid="save_service_desk_settings_button"
            data-qa-selector="save_service_desk_settings_button"
            :disabled="isTemplateSaving"
            @click="onSaveTemplate"
          >
            {{ __('Save changes') }}
          </gl-button>
        </div>
      </div>
    </div>
  </div>
</template>
