<script>
import {
  GlButton,
  GlToggle,
  GlLoadingIcon,
  GlSprintf,
  GlFormInputGroup,
  GlFormGroup,
  GlFormInput,
  GlLink,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
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
    GlFormGroup,
    GlFormInputGroup,
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
    emailSuffixHelpUrl() {
      return helpPagePath('user/project/service_desk.html', {
        anchor: 'configure-a-custom-email-address-suffix',
      });
    },
    customEmailAddressHelpUrl() {
      return helpPagePath('user/project/service_desk.html', {
        anchor: 'use-a-custom-email-address',
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
          <template v-if="email && hasCustomEmail" #description>
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
                __('Add a suffix to Service Desk email address. %{linkStart}Learn more.%{linkEnd}')
              "
            >
              <template #link="{ content }">
                <gl-link
                  :href="emailSuffixHelpUrl"
                  target="_blank"
                  class="gl-text-blue-600 font-size-inherit"
                  >{{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </template>
          <template v-else #description>
            <span class="gl-text-gray-900">
              <gl-sprintf
                :message="
                  __(
                    'To add a custom suffix, set up a Service Desk email address. %{linkStart}Learn more.%{linkEnd}',
                  )
                "
              >
                <template #link="{ content }">
                  <gl-link
                    :href="customEmailAddressHelpUrl"
                    target="_blank"
                    class="gl-text-blue-600 font-size-inherit"
                    >{{ content }}
                  </gl-link>
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
          />

          <template #description>
            {{ __('Name to be used as the sender for emails from Service Desk.') }}
          </template>
        </gl-form-group>

        <gl-button
          variant="confirm"
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
</template>
