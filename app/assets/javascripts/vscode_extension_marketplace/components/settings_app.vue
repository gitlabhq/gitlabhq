<script>
import { isObject } from 'lodash';
import { GlAccordion, GlAccordionItem, GlAlert, GlToggle } from '@gitlab/ui';
import { updateApplicationSettings } from '~/rest_api';
import { sprintf, s__ } from '~/locale';
import { logError } from '~/lib/logger';
import toast from '~/vue_shared/plugins/global_toast';
import SettingsForm from './settings_form.vue';

export default {
  components: {
    GlAccordion,
    GlAccordionItem,
    GlAlert,
    GlToggle,
    SettingsForm,
  },
  props: {
    presets: {
      type: Array,
      required: true,
    },
    initialSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      isEnabled: Boolean(this.initialSettings.enabled),
      isLoading: false,
      errorMessage: '',
    };
  },
  computed: {
    errorContent() {
      if (!this.errorMessage) {
        return null;
      }

      if (isObject(this.errorMessage)) {
        const list = Object.entries(this.errorMessage).flatMap(([key, messages]) =>
          [].concat(messages).map((value) => ({ key, value })),
        );

        return {
          list,
          title: s__('ExtensionMarketplace|Failed to update extension marketplace settings.'),
        };
      }

      return {
        list: null,
        title: sprintf(
          s__('ExtensionMarketplace|Failed to update extension marketplace settings. %{message}'),
          {
            message: this.errorMessage,
          },
        ),
      };
    },
    submitButtonAttrs() {
      return {
        'aria-describedby': 'extension-marketplace-settings-error-alert',
        loading: this.isLoading,
      };
    },
  },
  methods: {
    async submitEnabled(enabled) {
      // NOTE: We can update just `vscode_extension_marketplace_enabled` to control enabled without touching the rest
      const isSuccess = await this.submit({ vscode_extension_marketplace_enabled: enabled });

      if (isSuccess) {
        this.isEnabled = enabled;
      }
    },
    async submitForm(values) {
      // NOTE: We'll go ahead and update all of `vscode_extension_marketplace`.
      // Let's spread ontop of original `initialSettings` so that we don't unintentionally
      // overwrite anything.
      return this.submit({
        vscode_extension_marketplace: {
          ...this.initialSettings,
          enabled: this.isEnabled,
          ...values,
        },
      });
    },
    /**
     * @return {boolean} Whether the `submit` was successful or not. This encapsulated error handling already.
     */
    async submit(params) {
      if (this.isLoading) {
        return false;
      }

      this.isLoading = true;
      this.errorMessage = '';

      try {
        await updateApplicationSettings(params);

        toast(s__('ExtensionMarketplace|Extension marketplace settings updated.'));

        return true;
      } catch (e) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        logError('Failed to update extension marketplace settings. See error info:', e);

        this.errorMessage =
          e?.response?.data?.message ||
          s__('ExtensionMarketplace|An unknown error occurred. Please try again.');

        return false;
      } finally {
        this.isLoading = false;
      }
    },
  },
  FIELDS: {},
  MSG_ENABLE_LABEL: s__('ExtensionMarketplace|Enable Extension Marketplace'),
  MSG_ENABLE_DESCRIPTION: s__(
    'ExtensionMarketplace|Enable the VS Code extension marketplace for all users.',
  ),
  MSG_INNER_FORM: s__('ExtensionMarketplace|Extension registry settings'),
};
</script>
<template>
  <div>
    <gl-alert
      v-if="errorContent"
      id="extension-marketplace-settings-error-alert"
      class="gl-mb-3"
      variant="danger"
      :dismissible="false"
    >
      {{ errorContent.title }}
      <ul v-if="errorContent.list" class="gl-mb-0 gl-mt-3">
        <li v-for="({ key, value }, idx) in errorContent.list" :key="idx">
          <code>{{ key }}</code>
          <span>:</span>
          <span>{{ value }}</span>
        </li>
      </ul>
    </gl-alert>
    <gl-toggle
      :value="isEnabled"
      :is-loading="isLoading"
      :label="$options.MSG_ENABLE_LABEL"
      :help="$options.MSG_ENABLE_DESCRIPTION"
      label-position="top"
      @change="submitEnabled"
    />
    <gl-accordion :header-level="3" class="gl-pt-3">
      <gl-accordion-item :title="$options.MSG_INNER_FORM" class="gl-font-normal">
        <settings-form
          :presets="presets"
          :initial-settings="initialSettings"
          :submit-button-attrs="submitButtonAttrs"
          @submit="submitForm"
        />
      </gl-accordion-item>
    </gl-accordion>
  </div>
</template>
