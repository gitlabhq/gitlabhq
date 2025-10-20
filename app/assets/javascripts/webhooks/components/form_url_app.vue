<script>
import { cloneDeep, isEmpty } from 'lodash';
import { GlAlert, GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { scrollToElement } from '~/lib/utils/scroll_utils';
import HelpPopover from '~/vue_shared/components/help_popover.vue';

import FormUrlMaskItem from './form_url_mask_item.vue';

export default {
  components: {
    FormUrlMaskItem,
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInput,
    HelpPopover,
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
      url: this.initialUrl,
      items: this.getInitialItems(),
      isValidated: false,
      formEl: null,
    };
  },
  computed: {
    addItemText() {
      if (this.hasMaskItems) {
        return s__('Webhooks|+ Mask another portion of URL');
      }

      return s__('Webhooks|+ Add URL masking');
    },
    hasMaskItems() {
      return this.items.length > 0;
    },
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
      return isEmpty(this.initialUrlVariables) ? [] : cloneDeep(this.initialUrlVariables);
    },
    isExistingItem(index, key) {
      if (isEmpty(this.initialUrlVariables)) {
        return false;
      }

      const item = this.initialUrlVariables[index];
      return item && item.key === key;
    },
    keyInvalidFeedback(key) {
      if (this.isValidated && isEmpty(key)) {
        return __('This field is required.');
      }

      return null;
    },
    valueInvalidFeedback(index, key, value) {
      if (this.isExistingItem(index, key)) {
        return null;
      }

      if (this.isValidated && isEmpty(value)) {
        return __('This field is required.');
      }

      if (!isEmpty(value) && !this.url?.includes(value)) {
        return s__('Webhooks|Must match part of URL');
      }

      return null;
    },
    isValid() {
      this.isValidated = true;

      if (!this.urlState) {
        return false;
      }

      if (
        this.hasMaskItems &&
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
  urlPlaceholder: 'http://example.com/trigger-ci.json',
};
</script>

<template>
  <div>
    <gl-form-group
      ref="formUrl"
      :label="__('URL')"
      label-for="webhook-url"
      :description="
        s__(
          'Webhooks|The URL must be percent-encoded if it contains one or more special characters.',
        )
      "
      :invalid-feedback="s__('Webhooks|A URL is required.')"
      :state="urlState"
    >
      <gl-form-input
        id="webhook-url"
        v-model="url"
        name="hook[url]"
        class="gl-form-input-xl"
        :state="urlState"
        :placeholder="$options.urlPlaceholder"
        data-testid="webhook-url"
      />
      <gl-alert
        v-if="urlHasChanged"
        variant="warning"
        :dismissible="false"
        class="gl-form-input-xl gl-my-4"
      >
        {{ s__('Webhooks|The secret token is cleared on save unless it is updated.') }}
      </gl-alert>
    </gl-form-group>

    <div class="gl-my-5">
      <form-url-mask-item
        v-for="({ key, value }, index) in items"
        :key="index"
        :index="index"
        :item-key="key"
        :item-value="value"
        :is-existing="isExistingItem(index, key)"
        :key-invalid-feedback="keyInvalidFeedback(key)"
        :value-invalid-feedback="valueInvalidFeedback(index, key, value)"
        @input="onItemInput"
        @remove="removeItem"
      />

      <gl-button
        category="tertiary"
        variant="link"
        data-testid="add-item-button"
        @click="addItem"
        >{{ addItemText }}</gl-button
      >
      <help-popover>
        {{ s__('Webhooks|Hide sensitive data such as tokens in the UI.') }}
      </help-popover>

      <gl-form-group
        v-if="hasMaskItems"
        :label="s__('Webhooks|URL preview')"
        label-for="webhook-url-preview"
        class="gl-mt-5"
      >
        <gl-form-input
          id="webhook-url-preview"
          :value="maskedUrl"
          readonly
          name="hook[url]"
          data-testid="webhook-url-preview"
        />
      </gl-form-group>
    </div>
  </div>
</template>
