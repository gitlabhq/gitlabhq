<script>
import {
  GlAlert,
  GlButton,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormInputGroup,
  GlFormTextarea,
  GlLink,
  GlModal,
  GlModalDirective,
  GlSprintf,
  GlFormSelect,
} from '@gitlab/ui';
import { debounce } from 'lodash';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import ToggleButton from '~/vue_shared/components/toggle_button.vue';
import csrf from '~/lib/utils/csrf';
import service from '../services';
import { i18n, serviceOptions, JSON_VALIDATE_DELAY } from '../constants';

export default {
  i18n,
  csrf,
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    GlFormSelect,
    GlFormTextarea,
    GlLink,
    GlModal,
    GlSprintf,
    ClipboardButton,
    ToggleButton,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    prometheus: {
      type: Object,
      required: true,
      validator: ({ prometheusIsActivated }) => {
        return prometheusIsActivated !== undefined;
      },
    },
    generic: {
      type: Object,
      required: true,
      validator: ({ formPath }) => {
        return formPath !== undefined;
      },
    },
  },
  data() {
    return {
      activated: {
        generic: this.generic.initialActivated,
        prometheus: this.prometheus.prometheusIsActivated,
      },
      loading: false,
      authorizationKey: {
        generic: this.generic.initialAuthorizationKey,
        prometheus: this.prometheus.prometheusAuthorizationKey,
      },
      selectedEndpoint: null,
      options: serviceOptions,
      prometheusApiKey: this.prometheus.prometheusApiUrl,
      feedback: {
        variant: 'danger',
        feedbackMessage: null,
        isFeedbackDismissed: false,
      },
      testAlert: {
        json: null,
        error: null,
      },
      canSaveForm: false,
    };
  },
  computed: {
    sections() {
      return [
        {
          text: this.$options.i18n.usageSection,
          url: this.generic.alertsUsageUrl,
        },
        {
          text: this.$options.i18n.setupSection,
          url: this.generic.alertsSetupUrl,
        },
      ];
    },
    isGeneric() {
      return this.selectedEndpoint === 'generic';
    },
    selectedService() {
      return this.isGeneric
        ? {
            url: this.generic.url,
            authKey: this.authorizationKey.generic,
            active: this.activated.generic,
            resetKey: this.resetGenericKey.bind(this),
          }
        : {
            authKey: this.authorizationKey.prometheus,
            url: this.prometheus.prometheusUrl,
            active: this.activated.prometheus,
            resetKey: this.resetPrometheusKey.bind(this),
          };
    },
    showFeedbackMsg() {
      return this.feedback.feedbackMessage && !this.isFeedbackDismissed;
    },
    showAlertSave() {
      return (
        this.feedback.feedbackMessage === this.$options.i18n.testAlertFailed &&
        !this.isFeedbackDismissed
      );
    },
    prometheusInfo() {
      return !this.isGeneric ? this.$options.i18n.prometheusInfo : '';
    },
    prometheusFeatureEnabled() {
      return !this.isGeneric && this.glFeatures.alertIntegrationsDropdown;
    },
    jsonIsValid() {
      return this.testAlert.error === null;
    },
    canTestAlert() {
      return this.selectedService.active && this.testAlert.json !== null;
    },
    canSaveConfig() {
      return !this.loading && this.canSaveForm;
    },
  },
  watch: {
    'testAlert.json': debounce(function debouncedJsonValidate() {
      this.validateJson();
    }, JSON_VALIDATE_DELAY),
  },
  created() {
    if (this.glFeatures.alertIntegrationsDropdown) {
      this.selectedEndpoint = this.prometheus.prometheusIsActivated
        ? this.options[1].value
        : this.options[0].value;
    } else {
      this.selectedEndpoint = this.options[0].value;
    }
  },
  methods: {
    clearJson() {
      this.testAlert.json = null;
    },
    dismissFeedback() {
      this.feedback = { ...this.feedback, feedbackMessage: null };
      this.isFeedbackDismissed = false;
    },
    resetGenericKey() {
      return service
        .updateGenericKey({ endpoint: this.generic.formPath, params: { service: { token: '' } } })
        .then(({ data: { token } }) => {
          this.authorizationKey.generic = token;
          this.setFeedback({ feedbackMessage: this.$options.i18n.authKeyRest, variant: 'success' });
        })
        .catch(() => {
          this.setFeedback({ feedbackMessage: this.$options.i18n.errorKeyMsg, variant: 'danger' });
        });
    },
    resetPrometheusKey() {
      return service
        .updatePrometheusKey({ endpoint: this.prometheus.prometheusResetKeyPath })
        .then(({ data: { token } }) => {
          this.authorizationKey.prometheus = token;
          this.setFeedback({ feedbackMessage: this.$options.i18n.authKeyRest, variant: 'success' });
        })
        .catch(() => {
          this.setFeedback({ feedbackMessage: this.$options.i18n.errorKeyMsg, variant: 'danger' });
        });
    },
    toggleService(value) {
      this.canSaveForm = true;
      if (!this.glFeatures.alertIntegrationsDropdown) {
        this.toggleActivated(value);
      }

      if (this.isGeneric) {
        this.activated.generic = value;
      } else {
        this.activated.prometheus = value;
      }
    },
    toggleActivated(value) {
      return this.isGeneric
        ? this.toggleGenericActivated(value)
        : this.togglePrometheusActive(value);
    },
    toggleGenericActivated(value) {
      this.loading = true;
      return service
        .updateGenericActive({
          endpoint: this.generic.formPath,
          params: { service: { active: value } },
        })
        .then(() => {
          this.activated.generic = value;
          this.toggleSuccess(value);
        })
        .catch(() => {
          this.setFeedback({
            feedbackMessage: this.$options.i18n.errorMsg,
            variant: 'danger',
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    togglePrometheusActive(value) {
      this.loading = true;
      return service
        .updatePrometheusActive({
          endpoint: this.prometheus.prometheusFormPath,
          params: {
            token: this.$options.csrf.token,
            config: value ? 1 : 0,
            url: this.prometheusApiKey,
            redirect: window.location,
          },
        })
        .then(() => {
          this.activated.prometheus = value;
          this.toggleSuccess(value);
        })
        .catch(() => {
          this.setFeedback({
            feedbackMessage: this.$options.i18n.errorApiUrlMsg,
            variant: 'danger',
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    toggleSuccess(value) {
      if (value) {
        this.setFeedback({
          feedbackMessage: this.$options.i18n.endPointActivated,
          variant: 'info',
        });
      } else {
        this.setFeedback({
          feedbackMessage: this.$options.i18n.changesSaved,
          variant: 'info',
        });
      }
    },
    setFeedback({ feedbackMessage, variant }) {
      this.feedback = { feedbackMessage, variant };
    },
    validateJson() {
      this.testAlert.error = null;
      try {
        JSON.parse(this.testAlert.json);
      } catch (e) {
        this.testAlert.error = JSON.stringify(e.message);
      }
    },
    validateTestAlert() {
      this.loading = true;
      this.validateJson();
      return service
        .updateTestAlert({
          endpoint: this.selectedService.url,
          data: this.testAlert.json,
          authKey: this.selectedService.authKey,
        })
        .then(() => {
          this.setFeedback({
            feedbackMessage: this.$options.i18n.testAlertSuccess,
            variant: 'success',
          });
        })
        .catch(() => {
          this.setFeedback({
            feedbackMessage: this.$options.i18n.testAlertFailed,
            variant: 'danger',
          });
        })
        .finally(() => {
          this.loading = false;
        });
    },
    onSubmit() {
      this.toggleActivated(this.selectedService.active);
    },
    onReset() {
      this.testAlert.json = null;
      this.dismissFeedback();
    },
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showFeedbackMsg" :variant="feedback.variant" @dismiss="dismissFeedback">
      {{ feedback.feedbackMessage }}
      <gl-button
        v-if="showAlertSave"
        variant="danger"
        category="primary"
        class="gl-display-block gl-mt-3"
        @click="toggleActivated(selectedService.active)"
      >
        {{ __('Save anyway') }}
      </gl-button>
    </gl-alert>
    <div data-testid="alert-settings-description" class="gl-mt-5">
      <p v-for="section in sections" :key="section.text">
        <gl-sprintf :message="section.text">
          <template #link="{ content }">
            <gl-link :href="section.url" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </div>
    <gl-form @submit.prevent="onSubmit" @reset.prevent="onReset">
      <gl-form-group
        v-if="glFeatures.alertIntegrationsDropdown"
        :label="$options.i18n.integrationsLabel"
        label-for="integrations"
        label-class="label-bold"
      >
        <gl-form-select
          v-model="selectedEndpoint"
          :options="options"
          data-testid="alert-settings-select"
          @change="clearJson"
        />
        <span class="gl-text-gray-400">
          <gl-sprintf :message="$options.i18n.integrationsInfo">
            <template #link="{ content }">
              <gl-link
                class="gl-display-inline-block"
                href="https://gitlab.com/groups/gitlab-org/-/epics/3362"
                target="_blank"
                >{{ content }}</gl-link
              >
            </template>
          </gl-sprintf>
        </span>
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.activeLabel"
        label-for="activated"
        label-class="label-bold"
      >
        <toggle-button
          id="activated"
          :disabled-input="loading"
          :is-loading="loading"
          :value="selectedService.active"
          @change="toggleService"
        />
      </gl-form-group>
      <gl-form-group
        v-if="prometheusFeatureEnabled"
        :label="$options.i18n.apiBaseUrlLabel"
        label-for="api-url"
        label-class="label-bold"
      >
        <gl-form-input
          id="api-url"
          v-model="prometheusApiKey"
          type="url"
          :value="prometheusApiKey"
          :placeholder="$options.i18n.prometheusApiPlaceholder"
        />
        <span class="gl-text-gray-400">
          {{ $options.i18n.apiBaseUrlHelpText }}
        </span>
      </gl-form-group>
      <gl-form-group :label="$options.i18n.urlLabel" label-for="url" label-class="label-bold">
        <gl-form-input-group id="url" :readonly="true" :value="selectedService.url">
          <template #append>
            <clipboard-button
              :text="selectedService.url"
              :title="$options.i18n.copyToClipboard"
              class="gl-m-0!"
            />
          </template>
        </gl-form-input-group>
        <span class="gl-text-gray-400">
          {{ prometheusInfo }}
        </span>
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.authKeyLabel"
        label-for="authorization-key"
        label-class="label-bold"
      >
        <gl-form-input-group
          id="authorization-key"
          class="gl-mb-2"
          :readonly="true"
          :value="selectedService.authKey"
        >
          <template #append>
            <clipboard-button
              :text="selectedService.authKey"
              :title="$options.i18n.copyToClipboard"
              class="gl-m-0!"
            />
          </template>
        </gl-form-input-group>
        <gl-button v-gl-modal.authKeyModal class="gl-mt-3">{{ $options.i18n.resetKey }}</gl-button>
        <gl-modal
          modal-id="authKeyModal"
          :title="$options.i18n.resetKey"
          :ok-title="$options.i18n.resetKey"
          ok-variant="danger"
          @ok="selectedService.resetKey"
        >
          {{ $options.i18n.restKeyInfo }}
        </gl-modal>
      </gl-form-group>
      <gl-form-group
        v-if="glFeatures.alertIntegrationsDropdown"
        :label="$options.i18n.alertJson"
        label-for="alert-json"
        label-class="label-bold"
        :invalid-feedback="testAlert.error"
      >
        <gl-form-textarea
          id="alert-json"
          v-model.trim="testAlert.json"
          :disabled="!selectedService.active"
          :state="jsonIsValid"
          :placeholder="$options.i18n.alertJsonPlaceholder"
          rows="6"
          max-rows="10"
        />
      </gl-form-group>
      <gl-button :disabled="!canTestAlert" @click="validateTestAlert">{{
        $options.i18n.testAlertInfo
      }}</gl-button>
      <div
        v-if="glFeatures.alertIntegrationsDropdown"
        class="footer-block row-content-block gl-display-flex gl-justify-content-space-between"
      >
        <gl-button type="submit" variant="success" category="primary" :disabled="!canSaveConfig">
          {{ __('Save changes') }}
        </gl-button>
        <gl-button type="reset" variant="default" category="primary">
          {{ __('Cancel') }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>
