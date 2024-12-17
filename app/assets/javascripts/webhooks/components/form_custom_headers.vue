<script>
import { isEmpty } from 'lodash';
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { scrollToElement } from '~/lib/utils/common_utils';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { CUSTOM_HEADER_KEY_PATTERN } from '../constants';
import FormCustomHeaderItem from './form_custom_header_item.vue';

const MAXIMUM_CUSTOM_HEADERS = 20;

export default {
  components: {
    CrudComponent,
    FormCustomHeaderItem,
    GlButton,
  },
  props: {
    initialCustomHeaders: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      customHeaders: this.initialCustomHeaders,
      formEl: null,
      isValidated: false,
    };
  },
  computed: {
    maximumCustomHeadersReached() {
      return this.customHeaders.length >= MAXIMUM_CUSTOM_HEADERS;
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
    addItem() {
      this.customHeaders.push({ key: '', value: '' });
    },
    removeItem(index) {
      this.customHeaders.splice(index, 1);
    },
    onUpdate(index, newValues) {
      const copy = [...this.customHeaders];
      copy[index] = newValues;
      this.customHeaders = copy;
    },
    handleSubmit(e) {
      this.isValidated = true;

      for (const customHeader of this.customHeaders) {
        if (this.isInvalid(customHeader)) {
          scrollToElement(this.$refs.customHeaderCard.$el);
          e.preventDefault();
          e.stopPropagation();
          return;
        }
      }
    },
    keyIsValid(key) {
      return !isEmpty(key) && this.keyHasValidPattern(key);
    },
    keyHasValidPattern(key) {
      return CUSTOM_HEADER_KEY_PATTERN.test(key);
    },
    keyErrorFeedback(key) {
      if (!this.isValidated) return null;
      if (this.keyIsValid(key)) return null;

      return isEmpty(key)
        ? this.$options.i18n.inputRequired
        : s__(
            'Webhooks|Only alphanumeric characters, periods, dashes, and underscores allowed. Must start with a letter and end with a letter or number. Cannot have consecutive periods, dashes, or underscores.',
          );
    },
    valueErrorFeedback(value) {
      if (!this.isValidated) return null;
      if (!isEmpty(value)) return null;

      return this.$options.i18n.inputRequired;
    },
    isInvalid(customHeaderItem) {
      return isEmpty(customHeaderItem.key) || isEmpty(customHeaderItem.value);
    },
    isEmpty,
    s__,
  },
  i18n: {
    inputRequired: __('This field is required.'),
  },
};
</script>

<template>
  <crud-component
    ref="customHeaderCard"
    :title="s__('Webhooks|Custom headers')"
    icon="code"
    :count="customHeaders.length"
    class="gl-mb-5 gl-mt-3"
    data-testid="custom-headers-card"
  >
    <template #actions>
      <gl-button
        v-if="!maximumCustomHeadersReached"
        size="small"
        data-testid="add-custom-header"
        @click="addItem"
      >
        {{ s__('Webhooks|Add custom header') }}
      </gl-button>
      <span v-else class="gl-text-subtle">
        {{ s__("Webhooks|You've reached the maximum number of custom headers.") }}
      </span>
    </template>

    <form-custom-header-item
      v-for="({ value, key }, index) in customHeaders"
      :key="`custom-header-${index}`"
      :index="index"
      :header-key="key"
      :header-value="value"
      :key-state="keyIsValid(key) || !isValidated"
      :value-state="!isEmpty(value) || !isValidated"
      :invalid-key-feedback="keyErrorFeedback(key)"
      :invalid-value-feedback="valueErrorFeedback(value)"
      :class="{ 'gl-border-b gl-mb-4 gl-pb-4': index < customHeaders.length - 1 }"
      @update:header-key="onUpdate(index, { key: $event, value })"
      @update:header-value="onUpdate(index, { key, value: $event })"
      @remove="removeItem(index)"
    />

    <span v-if="customHeaders.length === 0" class="gl-text-subtle">
      {{ s__('Webhooks|No custom headers configured.') }}
    </span>
  </crud-component>
</template>
