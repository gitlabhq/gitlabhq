<script>
import { cloneDeep, isEmpty } from 'lodash';
import {
  GlFormGroup,
  GlFormInput,
  GlFormRadio,
  GlFormRadioGroup,
  GlLink,
  GlAlert,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { scrollToElement } from '~/lib/utils/common_utils';

import FormUrlMaskItem from './form_url_mask_item.vue';

export default {
  components: {
    FormUrlMaskItem,
    GlFormGroup,
    GlFormInput,
    GlFormRadio,
    GlFormRadioGroup,
    GlLink,
    GlAlert,
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
      isValidated: false,
      formEl: null,
    };
  },
  computed: {
    urlState() {
      return !this.isValidated || !isEmpty(this.url);
    },
    urlHasChanged() {
      return this.url !== this.initialUrl;
    },
    maskedUrl() {
      if (!this.url) {
        return null;
      }

      let maskedUrl = this.url;

      this.items.forEach(({ key, value }) => {
        if (!key || !value) {
          return;
        }

        maskedUrl = this.maskUrl(maskedUrl, key, value);
      });

      return maskedUrl;
    },
  },
  mounted() {
    this.formEl = document.querySelector('.js-webhook-form');

    this.formEl?.addEventListener('submit', this.handleSubmit);
  },
  destroy() {
    this.formEl?.removeEventListener('submit', this.handleSubmit);
  },
  methods: {
    getInitialItems() {
      return isEmpty(this.initialUrlVariables) ? [{}] : cloneDeep(this.initialUrlVariables);
    },
    isEditingItem(index, key) {
      if (isEmpty(this.initialUrlVariables)) {
        return false;
      }

      const item = this.initialUrlVariables[index];
      return item && item.key === key;
    },
    keyInvalidFeedback(key) {
      if (this.isValidated && isEmpty(key)) {
        return this.$options.i18n.inputRequired;
      }

      return null;
    },
    valueInvalidFeedback(index, key, value) {
      if (this.isEditingItem(index, key)) {
        return null;
      }

      if (this.isValidated && isEmpty(value)) {
        return this.$options.i18n.inputRequired;
      }

      if (!isEmpty(value) && !this.url?.includes(value)) {
        return this.$options.i18n.valuePartOfUrl;
      }

      return null;
    },
    isValid() {
      this.isValidated = true;

      if (!this.urlState) {
        return false;
      }

      if (
        this.maskEnabled &&
        this.items.some(
          ({ key, value }, index) =>
            this.keyInvalidFeedback(key) || this.valueInvalidFeedback(index, key, value),
        )
      ) {
        return false;
      }

      return true;
    },
    handleSubmit(e) {
      if (!this.isValid()) {
        scrollToElement(this.$refs.formUrl.$el);
        e.preventDefault();
        e.stopPropagation();
      }
    },
    maskUrl(url, key, value) {
      return url.split(value).join(`{${key}}`);
    },
    onItemInput({ index, key, value }) {
      const copy = [...this.items];
      copy[index] = { key, value };
      this.items = copy;
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
    inputRequired: __('This field is required.'),
    radioFullUrlText: s__('Webhooks|Show full URL'),
    radioMaskUrlText: s__('Webhooks|Mask portions of URL'),
    radioMaskUrlHelp: s__('Webhooks|Do not show sensitive data such as tokens in the UI.'),
    urlDescription: s__(
      'Webhooks|URL must be percent-encoded if it contains one or more special characters.',
    ),
    urlLabel: __('URL'),
    urlPlaceholder: 'http://example.com/trigger-ci.json',
    urlPreview: s__('Webhooks|URL preview'),
    valuePartOfUrl: s__('Webhooks|Must match part of URL'),
    tokenWillBeCleared: s__(
      'Webhooks|Secret token will be cleared on save unless token is updated.',
    ),
  },
};
</script>

<template>
  <div>
    <gl-form-group
      ref="formUrl"
      :label="$options.i18n.urlLabel"
      label-for="webhook-url"
      :description="$options.i18n.urlDescription"
      :invalid-feedback="$options.i18n.inputRequired"
      :state="urlState"
    >
      <gl-form-input
        id="webhook-url"
        v-model="url"
        name="hook[url]"
        class="gl-form-input-xl"
        :state="urlState"
        :placeholder="$options.i18n.urlPlaceholder"
        data-testid="form-url"
      />
      <gl-alert
        v-if="urlHasChanged"
        variant="warning"
        :dismissible="false"
        class="gl-form-input-xl gl-my-4"
      >
        {{ $options.i18n.tokenWillBeCleared }}
      </gl-alert>
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
          :is-editing="isEditingItem(index, key)"
          :key-invalid-feedback="keyInvalidFeedback(key)"
          :value-invalid-feedback="valueInvalidFeedback(index, key, value)"
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
