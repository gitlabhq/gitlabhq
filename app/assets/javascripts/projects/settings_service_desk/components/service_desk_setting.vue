<script>
import { GlDeprecatedButton, GlFormSelect, GlToggle, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import tooltip from '~/vue_shared/directives/tooltip';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import eventHub from '../event_hub';

export default {
  name: 'ServiceDeskSetting',
  directives: {
    tooltip,
  },
  components: {
    ClipboardButton,
    GlDeprecatedButton,
    GlFormSelect,
    GlToggle,
    GlLoadingIcon,
  },
  mixins: [glFeatureFlagsMixin()],
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
      return Boolean(this.glFeatures.serviceDeskCustomAddress);
    },
  },
  methods: {
    onCheckboxToggle(isChecked) {
      eventHub.$emit('serviceDeskEnabledCheckboxToggled', isChecked);
    },
    onSaveTemplate() {
      eventHub.$emit('serviceDeskTemplateSave', {
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
      label="Service desk"
      label-position="left"
      @change="onCheckboxToggle"
    />
    <label class="align-middle" for="service-desk-checkbox">
      {{ __('Activate Service Desk') }}
    </label>
    <div v-if="isEnabled" class="row mt-3">
      <div class="col-md-9 mb-0">
        <strong id="incoming-email-describer" class="d-block mb-1">
          {{ __('Forward external support email address to') }}
        </strong>
        <template v-if="incomingEmail">
          <div class="input-group">
            <input
              ref="service-desk-incoming-email"
              type="text"
              class="form-control incoming-email h-auto"
              :placeholder="__('Incoming email')"
              :aria-label="__('Incoming email')"
              aria-describedby="incoming-email-describer"
              :value="incomingEmail"
              disabled="true"
            />
            <div class="input-group-append">
              <clipboard-button
                :title="__('Copy')"
                :text="incomingEmail"
                css-class="btn qa-clipboard-button"
              />
            </div>
          </div>
        </template>
        <template v-else>
          <gl-loading-icon :inline="true" />
          <span class="sr-only">{{ __('Fetching incoming email') }}</span>
        </template>

        <label for="service-desk-template-select" class="mt-3">
          {{ __('Template to append to all Service Desk issues') }}
        </label>
        <gl-form-select
          id="service-desk-template-select"
          v-model="selectedTemplate"
          :options="templateOptions"
        />
        <label for="service-desk-email-from-name" class="mt-3">
          {{ __('Email display name') }}
        </label>
        <input id="service-desk-email-from-name" v-model.trim="outgoingName" class="form-control" />
        <span class="form-text text-muted">
          {{ __('Emails sent from Service Desk will have this name') }}
        </span>
        <template v-if="hasProjectKeySupport">
          <label for="service-desk-project-suffix" class="mt-3">
            {{ __('Project name suffix') }}
          </label>
          <input id="service-desk-project-suffix" v-model.trim="projectKey" class="form-control" />
          <span class="form-text text-muted mb-3">
            {{
              __(
                'Project name suffix is a user-defined string which will be appended to the project path, and will form the Service Desk email address.',
              )
            }}
          </span>
        </template>
        <gl-deprecated-button
          variant="success"
          :disabled="isTemplateSaving"
          @click="onSaveTemplate"
          >{{ __('Save template') }}</gl-deprecated-button
        >
      </div>
    </div>
  </div>
</template>
