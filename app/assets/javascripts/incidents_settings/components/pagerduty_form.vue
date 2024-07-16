<script>
import {
  GlAlert,
  GlButton,
  GlSprintf,
  GlLink,
  GlIcon,
  GlFormGroup,
  GlFormInputGroup,
  GlToggle,
  GlModal,
  GlModalDirective,
} from '@gitlab/ui';
import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { I18N_PAGERDUTY_SETTINGS_FORM, CONFIGURE_PAGERDUTY_WEBHOOK_DOCS_LINK } from '../constants';

export default {
  components: {
    GlAlert,
    GlButton,
    GlSprintf,
    GlLink,
    GlIcon,
    GlFormGroup,
    GlFormInputGroup,
    GlToggle,
    GlModal,
    ClipboardButton,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  inject: ['service', 'pagerDutySettings'],
  data() {
    return {
      active: this.pagerDutySettings.active,
      webhookUrl: this.pagerDutySettings.webhookUrl,
      loading: false,
      resettingWebhook: false,
      webhookUpdateFailed: false,
      showAlert: false,
    };
  },
  i18n: I18N_PAGERDUTY_SETTINGS_FORM,
  modal: {
    id: 'resetWebhookModal',
    actionPrimary: {
      text: I18N_PAGERDUTY_SETTINGS_FORM.webhookUrl.resetWebhookUrl,
      attributes: {
        variant: 'danger',
      },
    },
    actionCancel: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  CONFIGURE_PAGERDUTY_WEBHOOK_DOCS_LINK,
  computed: {
    formData() {
      return {
        pagerduty_active: this.active,
      };
    },
    isSaveDisabled() {
      return this.loading || this.resettingWebhook;
    },
    webhookUpdateAlertMsg() {
      return this.webhookUpdateFailed
        ? this.$options.i18n.webhookUrl.updateErrMsg
        : this.$options.i18n.webhookUrl.updateSuccessMsg;
    },
    webhookUpdateAlertVariant() {
      return this.webhookUpdateFailed ? 'danger' : 'success';
    },
  },
  methods: {
    updatePagerDutyIntegrationSettings() {
      this.loading = true;

      this.service.updateSettings(this.formData).catch(() => {
        this.loading = false;
      });
    },
    resetWebhookUrl() {
      this.resettingWebhook = true;

      this.service
        .resetWebhookUrl()
        .then(({ data: { pagerduty_webhook_url: url } }) => {
          this.webhookUrl = url;
          this.showAlert = true;
          this.webhookUpdateFailed = false;
        })
        .catch(() => {
          this.showAlert = true;
          this.webhookUpdateFailed = true;
        })
        .finally(() => {
          this.resettingWebhook = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <gl-alert
      v-if="showAlert"
      class="gl-mb-3"
      :variant="webhookUpdateAlertVariant"
      @dismiss="showAlert = false"
    >
      {{ webhookUpdateAlertMsg }}
    </gl-alert>

    <p>
      <gl-sprintf :message="$options.i18n.introText">
        <template #link="{ content }">
          <gl-link
            :href="$options.CONFIGURE_PAGERDUTY_WEBHOOK_DOCS_LINK"
            target="_blank"
            class="gl-inline-flex"
          >
            <span>{{ content }}</span>
            <gl-icon name="external-link" />
          </gl-link>
        </template>
      </gl-sprintf>
    </p>
    <form ref="settingsForm">
      <gl-form-group class="col-8 col-md-9 gl-p-0">
        <gl-toggle
          id="active"
          v-model="active"
          :disabled="isSaveDisabled"
          :is-loading="loading"
          :label="$options.i18n.activeToggle.label"
          @change="updatePagerDutyIntegrationSettings"
        />
      </gl-form-group>

      <gl-form-group
        class="col-8 col-md-9 gl-p-0"
        :label="$options.i18n.webhookUrl.label"
        label-for="url"
      >
        <gl-form-input-group id="url" data-testid="webhook-url" readonly :value="webhookUrl">
          <template #append>
            <clipboard-button
              :text="webhookUrl"
              :title="$options.i18n.webhookUrl.copyToClipboard"
            />
          </template>
        </gl-form-input-group>

        <gl-button
          v-gl-modal.resetWebhookModal
          class="gl-mt-5"
          :disabled="loading"
          :loading="resettingWebhook"
          data-testid="webhook-reset-btn"
        >
          {{ $options.i18n.webhookUrl.resetWebhookUrl }}
        </gl-button>
        <gl-modal
          :modal-id="$options.modal.id"
          :title="$options.i18n.webhookUrl.resetWebhookUrl"
          :action-primary="$options.modal.actionPrimary"
          :action-cancel="$options.modal.actionCancel"
          @primary="resetWebhookUrl"
        >
          {{ $options.i18n.webhookUrl.restKeyInfo }}
        </gl-modal>
      </gl-form-group>
    </form>
  </div>
</template>
