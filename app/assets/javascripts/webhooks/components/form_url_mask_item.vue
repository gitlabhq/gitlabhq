<script>
import { isEmpty } from 'lodash';
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';
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
    isEditing: {
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
      return this.isEditing ? MASK_ITEM_VALUE_HIDDEN : this.itemValue;
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
        :disabled="isEditing"
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
        :disabled="isEditing"
        :state="keyState"
        @input="onKeyInput"
      />
    </gl-form-group>
    <gl-button
      icon="remove"
      :aria-label="__('Remove')"
      :disabled="isEditing"
      class="gl-mt-6"
      @click="onRemoveClick"
    />
  </div>
</template>
