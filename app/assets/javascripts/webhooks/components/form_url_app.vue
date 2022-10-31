<script>
import { cloneDeep, isEmpty } from 'lodash';
import { GlFormGroup, GlFormInput, GlFormRadio, GlFormRadioGroup, GlLink } from '@gitlab/ui';
import { __, s__ } from '~/locale';

import FormUrlMaskItem from './form_url_mask_item.vue';

export default {
  components: {
    FormUrlMaskItem,
    GlFormGroup,
    GlFormInput,
    GlFormRadio,
    GlFormRadioGroup,
    GlLink,
  },
  props: {
    initialUrl: {
      type: String,
      required: false,
      default: null,
    },
    initialUrlVariables: {
      type: Array,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      maskEnabled: !isEmpty(this.initialUrlVariables),
      url: this.initialUrl,
      items: this.getInitialItems(),
    };
  },
  computed: {
    maskedUrl() {
      if (!this.url) {
        return null;
      }

      let maskedUrl = this.url;

      this.items.forEach(({ key, value }) => {
        if (!key || !value) {
          return;
        }

        const replacementExpression = new RegExp(value, 'g');
        maskedUrl = maskedUrl.replace(replacementExpression, `{${key}}`);
      });

      return maskedUrl;
    },
  },
  methods: {
    getInitialItems() {
      return isEmpty(this.initialUrlVariables) ? [{}] : cloneDeep(this.initialUrlVariables);
    },
    isEditingItem(key) {
      if (isEmpty(this.initialUrlVariables)) {
        return false;
      }

      return this.initialUrlVariables.some((item) => item.key === key);
    },
    onItemInput({ index, key, value }) {
      this.$set(this.items, index, { key, value });
    },
    addItem() {
      this.items.push({});
    },
    removeItem(index) {
      this.items.splice(index, 1);
    },
  },
  i18n: {
    addItem: s__('Webhooks|+ Mask another portion of URL'),
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
        data-testid="form-url"
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
        <form-url-mask-item
          v-for="({ key, value }, index) in items"
          :key="index"
          :index="index"
          :item-key="key"
          :item-value="value"
          :is-editing="isEditingItem(key)"
          @input="onItemInput"
          @remove="removeItem"
        />
        <div class="gl-mb-5">
          <gl-link @click="addItem">{{ $options.i18n.addItem }}</gl-link>
        </div>

        <gl-form-group :label="$options.i18n.urlPreview" label-for="webhook-url-preview">
          <gl-form-input
            id="webhook-url-preview"
            :value="maskedUrl"
            readonly
            name="hook[url]"
            data-testid="form-url-preview"
          />
        </gl-form-group>
      </div>
    </div>
  </div>
</template>
