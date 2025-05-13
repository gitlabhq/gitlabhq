<script>
import { isEmpty } from 'lodash';
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';
import { MASK_ITEM_VALUE_HIDDEN } from '../constants';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
  },
  props: {
    index: {
      type: Number,
      required: false,
      default: null,
    },
    itemKey: {
      type: String,
      required: false,
      default: null,
    },
    itemValue: {
      type: String,
      required: false,
      default: null,
    },
    isExisting: {
      type: Boolean,
      required: false,
      default: false,
    },
    keyInvalidFeedback: {
      type: String,
      required: false,
      default: null,
    },
    valueInvalidFeedback: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    keyInputId() {
      return this.inputId('key');
    },
    valueInputId() {
      return this.inputId('value');
    },
    keyState() {
      return isEmpty(this.keyInvalidFeedback);
    },
    valueState() {
      return isEmpty(this.valueInvalidFeedback);
    },
    displayValue() {
      return this.isExisting ? MASK_ITEM_VALUE_HIDDEN : this.itemValue;
    },
    removeAriaLabel() {
      return sprintf(s__('Webhooks|Remove item %{index}'), { index: this.index + 1 });
    },
  },
  methods: {
    inputId(type) {
      return `webhook-url-mask-item-${type}-${this.index}`;
    },
    inputName(type) {
      return `hook[url_variables][][${type}]`;
    },
    onKeyInput(key) {
      this.$emit('input', { index: this.index, key, value: this.itemValue });
    },
    onValueInput(value) {
      this.$emit('input', { index: this.index, key: this.itemKey, value });
    },
    onRemoveClick() {
      this.$emit('remove', this.index);
    },
  },
  i18n: {
    keyLabel: s__('Webhooks|How it looks in the UI'),
    valueLabel: s__('Webhooks|Sensitive portion of URL'),
  },
};
</script>

<template>
  <div class="gl-mb-3 gl-flex gl-items-start gl-gap-3">
    <gl-form-group
      :label="$options.i18n.valueLabel"
      :label-for="valueInputId"
      :invalid-feedback="valueInvalidFeedback"
      :state="valueState"
      class="gl-mb-0 gl-grow"
      data-testid="mask-item-value"
    >
      <gl-form-input
        :id="valueInputId"
        :name="inputName('value')"
        :value="displayValue"
        :disabled="isExisting"
        :state="valueState"
        @input="onValueInput"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.keyLabel"
      :label-for="keyInputId"
      :invalid-feedback="keyInvalidFeedback"
      :state="keyState"
      class="gl-mb-0 gl-grow"
      data-testid="mask-item-key"
    >
      <gl-form-input
        :id="keyInputId"
        :name="inputName('key')"
        :value="itemKey"
        :disabled="isExisting"
        :state="keyState"
        @input="onKeyInput"
      />
    </gl-form-group>
    <gl-button
      icon="remove"
      :aria-label="removeAriaLabel"
      :disabled="isExisting"
      class="gl-mt-6"
      @click="onRemoveClick"
    />
  </div>
</template>
