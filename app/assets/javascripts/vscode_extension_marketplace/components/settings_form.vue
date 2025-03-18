<script>
import { uniqueId, pick } from 'lodash';
import { GlButton, GlForm, GlFormFields, GlIcon, GlLink, GlSprintf, GlToggle } from '@gitlab/ui';
import { s__ } from '~/locale';
import { isValidURL, isAbsolute } from '~/lib/utils/url_utility';
import { PRESET_OPEN_VSX, PRESET_CUSTOM } from '../constants';

const validateRequired = (invalidMsg) => (val) => {
  if (val) {
    return '';
  }

  return invalidMsg;
};

const validateURL = (invalidMsg) => (val) => {
  if (isAbsolute(val) && isValidURL(val)) {
    return '';
  }

  return invalidMsg;
};

const MSG_VALID_URL = s__('ExtensionMarketplace|A valid URL is required.');

const createUrlField = (label) => ({
  label,
  validators: [validateURL(MSG_VALID_URL), validateRequired(MSG_VALID_URL)],
  inputAttrs: {
    width: 'lg',
    placeholder: 'https://...',
  },
});

const createReadonlyUrlField = (label) => ({
  label,
  inputAttrs: {
    width: 'lg',
    readonly: true,
    'aria-description': s__(
      'ExtensionMarketplace|Disable Open VSX extension registry to set a custom value for this field.',
    ),
  },
});

const FIELDS = {
  useOpenVsx: {
    label: s__('ExtensionMarketplace|Use Open VSX extension registry'),
  },
  serviceUrl: createUrlField(s__('ExtensionMarketplace|Service URL')),
  itemUrl: createUrlField(s__('ExtensionMarketplace|Item URL')),
  resourceUrlTemplate: createUrlField(s__('ExtensionMarketplace|Resource URL Template')),
  presetServiceUrl: createReadonlyUrlField(s__('ExtensionMarketplace|Service URL')),
  presetItemUrl: createReadonlyUrlField(s__('ExtensionMarketplace|Item URL')),
  presetResourceUrlTemplate: createReadonlyUrlField(
    s__('ExtensionMarketplace|Resource URL Template'),
  ),
};

export default {
  components: {
    GlButton,
    GlForm,
    GlFormFields,
    GlIcon,
    GlLink,
    GlSprintf,
    GlToggle,
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
    submitButtonAttrs: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    const { preset, custom_values: initialCustomValues } = this.initialSettings;

    return {
      formId: uniqueId('extension-marketplace-settings-form-'),
      formValues: {
        useOpenVsx: !preset || preset === PRESET_OPEN_VSX,
        // URL fields for "custom" preset.
        serviceUrl: '',
        itemUrl: '',
        resourceUrlTemplate: '',
        // URL fields for other presets. The inputs are readonly.
        presetServiceUrl: '',
        presetItemUrl: '',
        presetResourceUrlTemplate: '',
      },
      customValues: {
        serviceUrl: initialCustomValues?.service_url || '',
        itemUrl: initialCustomValues?.item_url || '',
        resourceUrlTemplate: initialCustomValues?.resource_url_template || '',
      },
    };
  },
  computed: {
    preset() {
      return this.formValues.useOpenVsx ? PRESET_OPEN_VSX : PRESET_CUSTOM;
    },
    isCustomPreset() {
      return this.preset === PRESET_CUSTOM;
    },
    payload() {
      if (this.isCustomPreset) {
        return {
          preset: this.preset,
          custom_values: {
            service_url: this.formValues.serviceUrl,
            item_url: this.formValues.itemUrl,
            resource_url_template: this.formValues.resourceUrlTemplate,
          },
        };
      }

      return {
        preset: this.preset,
      };
    },
    formFields() {
      if (this.isCustomPreset) {
        return pick(FIELDS, ['useOpenVsx', 'serviceUrl', 'itemUrl', 'resourceUrlTemplate']);
      }

      return pick(FIELDS, [
        'useOpenVsx',
        'presetServiceUrl',
        'presetItemUrl',
        'presetResourceUrlTemplate',
      ]);
    },
  },
  watch: {
    preset: {
      immediate: true,
      handler(val, prevVal) {
        if (prevVal === PRESET_CUSTOM) {
          this.customValues.serviceUrl = this.formValues.serviceUrl;
          this.customValues.itemUrl = this.formValues.itemUrl;
          this.customValues.resourceUrlTemplate = this.formValues.resourceUrlTemplate;
        }

        if (val === PRESET_CUSTOM) {
          this.formValues.serviceUrl = this.customValues.serviceUrl;
          this.formValues.itemUrl = this.customValues.itemUrl;
          this.formValues.resourceUrlTemplate = this.customValues.resourceUrlTemplate;
        } else {
          const values = this.presets.find(({ key }) => key === val)?.values;

          this.formValues.presetServiceUrl = values?.serviceUrl;
          this.formValues.presetItemUrl = values?.itemUrl;
          this.formValues.presetResourceUrlTemplate = values?.resourceUrlTemplate;
        }
      },
    },
  },
  methods: {
    onSubmit() {
      this.$emit('submit', this.payload);
    },
  },
  MSG_OPEN_VSX_DESCRIPTION: s__(
    'ExtensionMarketplace|Learn more about the %{linkStart}Open VSX Registry%{linkEnd}',
  ),
};
</script>

<template>
  <gl-form :id="formId" @submit.prevent>
    <gl-form-fields v-model="formValues" :fields="formFields" :form-id="formId" @submit="onSubmit">
      <template #input(useOpenVsx)="{ id, value, input, blur }">
        <gl-toggle
          :id="id"
          :label="formFields.useOpenVsx.label"
          label-position="hidden"
          :value="value"
          @change="input"
          @blur="blur"
        />
      </template>
      <template #group(useOpenVsx)-description>
        <gl-sprintf :message="$options.MSG_OPEN_VSX_DESCRIPTION">
          <template #link="{ content }">
            <gl-link href="https://open-vsx.org/about" target="_blank"
              >{{ content }} <gl-icon name="external-link"
            /></gl-link>
          </template>
        </gl-sprintf>
      </template>
    </gl-form-fields>
    <div class="gl-flex">
      <gl-button
        class="js-no-auto-disable"
        type="submit"
        variant="confirm"
        category="primary"
        v-bind="submitButtonAttrs"
      >
        {{ __('Save changes') }}
      </gl-button>
    </div>
  </gl-form>
</template>
