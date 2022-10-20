<script>
import { GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import { s__ } from '~/locale';

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
  },
  computed: {
    keyInputId() {
      return this.inputId('key');
    },
    valueInputId() {
      return this.inputId('value');
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
  <div class="gl-display-flex gl-align-items-flex-end gl-gap-3 gl-mb-3">
    <gl-form-group
      :label="$options.i18n.valueLabel"
      :label-for="valueInputId"
      class="gl-flex-grow-1 gl-mb-0"
      data-testid="mask-item-value"
    >
      <gl-form-input
        :id="valueInputId"
        :name="inputName('value')"
        :value="itemValue"
        @input="onValueInput"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.keyLabel"
      :label-for="keyInputId"
      class="gl-flex-grow-1 gl-mb-0"
      data-testid="mask-item-key"
    >
      <gl-form-input
        :id="keyInputId"
        :name="inputName('key')"
        :value="itemKey"
        @input="onKeyInput"
      />
    </gl-form-group>
    <gl-button icon="remove" :aria-label="__('Remove')" @click="onRemoveClick" />
  </div>
</template>
