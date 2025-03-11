<script>
import { uniqueId, isObject } from 'lodash';
import { GlAlert, GlButton, GlForm, GlFormFields, GlFormTextarea } from '@gitlab/ui';
import { updateApplicationSettings } from '~/rest_api';
import { sprintf, s__, __ } from '~/locale';
import { logError } from '~/lib/logger';
import toast from '~/vue_shared/plugins/global_toast';

export default {
  components: {
    GlAlert,
    GlButton,
    GlForm,
    GlFormFields,
    GlFormTextarea,
  },
  props: {
    initialSettings: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      formId: uniqueId('extension-marketplace-settings-form-'),
      formValues: {
        settings: JSON.stringify(this.initialSettings, null, 2),
      },
      isLoading: false,
      errorMessage: '',
    };
  },
  computed: {
    payload() {
      return JSON.parse(this.formValues.settings);
    },
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
  },
  methods: {
    async onSubmit() {
      if (this.isLoading) {
        return;
      }

      this.isLoading = true;
      this.errorMessage = '';

      try {
        await updateApplicationSettings({
          vscode_extension_marketplace: this.payload,
        });

        toast(s__('ExtensionMarketplace|Extension marketplace settings updated.'));
      } catch (e) {
        // eslint-disable-next-line @gitlab/require-i18n-strings
        logError('Failed to update extension marketplace settings. See error info:', e);

        this.errorMessage =
          e?.response?.data?.message ||
          s__('ExtensionMarketplace|An unknown error occurred. Please try again.');
      } finally {
        this.isLoading = false;
      }
    },
  },
  FIELDS: {
    settings: {
      label: __('Settings'),
    },
  },
};
</script>
<template>
  <div>
    <gl-form :id="formId" @submit.prevent>
      <gl-alert
        v-if="errorContent"
        id="extensions-marketplace-settings-error-alert"
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
      <gl-form-fields
        v-model="formValues"
        :fields="$options.FIELDS"
        :form-id="formId"
        @submit="onSubmit"
      >
        <template #input(settings)="{ id, value, input, blur }">
          <gl-form-textarea
            :id="id"
            class="!gl-font-monospace"
            :value="value"
            :state="!Boolean(errorContent)"
            @input="input"
            @blur="blur"
          />
        </template>
      </gl-form-fields>
      <div class="gl-flex">
        <gl-button
          class="js-no-auto-disable"
          aria-describedby="extensions-marketplace-settings-error-alert"
          type="submit"
          variant="confirm"
          category="primary"
          :loading="isLoading"
        >
          {{ __('Save changes') }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>
