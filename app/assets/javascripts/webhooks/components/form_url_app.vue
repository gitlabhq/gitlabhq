<script>
import { GlFormGroup, GlFormInput, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { __, s__ } from '~/locale';

import FormUrlMaskItem from './form_url_mask_item.vue';

export default {
  components: {
    FormUrlMaskItem,
    GlFormGroup,
    GlFormInput,
    GlFormRadio,
    GlFormRadioGroup,
  },
  data() {
    return {
      maskEnabled: false,
      url: null,
    };
  },
  computed: {
    maskedUrl() {
      return this.url;
    },
  },
  i18n: {
    radioFullUrlText: s__('Webhooks|Show full URL'),
    radioMaskUrlText: s__('Webhooks|Mask portions of URL'),
    radioMaskUrlHelp: s__('Webhooks|Do not show sensitive data such as tokens in the UI.'),
    urlDescription: s__(
      'Webhooks|URL must be percent-encoded if it contains one or more special characters.',
    ),
    urlLabel: __('URL'),
    urlPlaceholder: 'http://example.com/trigger-ci.json',
    urlPreview: s__('Webhooks|URL preview'),
  },
};
</script>

<template>
  <div>
    <gl-form-group
      :label="$options.i18n.urlLabel"
      label-for="webhook-url"
      :description="$options.i18n.urlDescription"
    >
      <gl-form-input
        id="webhook-url"
        v-model="url"
        name="hook[url]"
        :placeholder="$options.i18n.urlPlaceholder"
      />
    </gl-form-group>
    <div class="gl-mt-5">
      <gl-form-radio-group v-model="maskEnabled">
        <gl-form-radio :value="false">{{ $options.i18n.radioFullUrlText }}</gl-form-radio>
        <gl-form-radio :value="true"
          >{{ $options.i18n.radioMaskUrlText }}
          <template #help>
            {{ $options.i18n.radioMaskUrlHelp }}
          </template>
        </gl-form-radio>
      </gl-form-radio-group>

      <div v-if="maskEnabled" class="gl-ml-6" data-testid="url-mask-section">
        <form-url-mask-item :index="0" />
        <gl-form-group :label="$options.i18n.urlPreview" label-for="webhook-url-preview">
          <gl-form-input id="webhook-url-preview" :value="maskedUrl" readonly />
        </gl-form-group>
      </div>
    </div>
  </div>
</template>
