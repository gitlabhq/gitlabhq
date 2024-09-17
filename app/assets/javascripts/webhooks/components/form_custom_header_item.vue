<script>
import { isEmpty } from 'lodash';
import { GlButton, GlFormGroup, GlFormInput, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { MASK_ITEM_VALUE_HIDDEN } from '../constants';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    headerKey: {
      type: String,
      required: true,
    },
    headerValue: {
      type: String,
      required: true,
    },
    keyState: {
      type: Boolean,
      required: true,
    },
    valueState: {
      type: Boolean,
      required: true,
    },
    invalidKeyFeedback: {
      type: String,
      required: false,
      default: '',
    },
    invalidValueFeedback: {
      type: String,
      required: false,
      default: '',
    },
    index: {
      type: Number,
      required: true,
    },
  },
  computed: {
    valueIsHidden() {
      return MASK_ITEM_VALUE_HIDDEN === this.headerValue;
    },
    keyInputId() {
      return `webhook-custom-header-key-${this.headerKey}`;
    },
    valueInputId() {
      return `webhook-custom-header-value-${this.headerKey}`;
    },
  },
  methods: {
    isEmpty,
    s__,
  },
  i18n: {
    removeButton: __('Remove'),
  },
};
</script>

<template>
  <div class="gl-flex gl-items-start gl-gap-3">
    <gl-form-group
      :label="s__('Webhooks|Header name')"
      :label-for="keyInputId"
      :invalid-feedback="invalidKeyFeedback"
      class="gl-mb-0 gl-basis-1/2"
      :label-class="{ 'gl-sr-only': index > 0 }"
      data-testid="custom-header-item-key"
    >
      <gl-form-input
        :id="keyInputId"
        :value="headerKey"
        name="hook[custom_headers][][key]"
        :readonly="valueIsHidden"
        :state="keyState"
        @input="$emit('update:header-key', $event)"
      />
    </gl-form-group>
    <gl-form-group
      :label="s__('Webhooks|Header value')"
      :label-for="valueInputId"
      :invalid-feedback="invalidValueFeedback"
      class="gl-mb-0 gl-basis-1/2"
      :label-class="{ 'gl-sr-only': index > 0 }"
      data-testid="custom-header-item-value"
    >
      <gl-form-input
        :id="valueInputId"
        :value="headerValue"
        name="hook[custom_headers][][value]"
        :readonly="valueIsHidden"
        :state="valueState"
        @input="$emit('update:header-value', $event)"
      />
    </gl-form-group>
    <gl-button
      v-gl-tooltip
      category="tertiary"
      icon="remove"
      :title="$options.i18n.removeButton"
      :aria-label="$options.i18n.removeButton"
      :class="{ 'gl-mt-6': index === 0 }"
      @click="$emit('remove')"
    />
  </div>
</template>
