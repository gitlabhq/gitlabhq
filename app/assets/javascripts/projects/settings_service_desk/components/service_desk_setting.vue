<script>
import { GlButton, GlFormSelect, GlToggle, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

export default {
  i18n: {
    toggleLabel: __('Activate Service Desk'),
  },
  components: {
    ClipboardButton,
    GlButton,
    GlFormSelect,
    GlToggle,
    GlLoadingIcon,
    GlSprintf,
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
      outgoingName: this.initialOutgoingName || __('GitLab Support Bot'),
      projectKey: this.initialProjectKey,
    };
  },
  computed: {
    templateOptions() {
      return [''].concat(this.templates);
    },
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
      });
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

        <template v-if="hasProjectKeySupport">
          <label for="service-desk-project-suffix" class="mt-3">
            {{ __('Project name suffix') }}
          </label>
          <input id="service-desk-project-suffix" v-model.trim="projectKey" class="form-control" />
          <span class="form-text text-muted">
            {{
              __('A string appended to the project path to form the Service Desk email address.')
            }}
          </span>
        </template>

        <label for="service-desk-template-select" class="mt-3">
          {{ __('Template to append to all Service Desk issues') }}
        </label>
        <gl-form-select
          id="service-desk-template-select"
          v-model="selectedTemplate"
          data-qa-selector="service_desk_template_dropdown"
          :options="templateOptions"
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
