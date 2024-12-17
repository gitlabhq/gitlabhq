<script>
import { __ } from '~/locale';

/**
 * Usage:
 *
 * With a `value` prop:
 *
 * <runner-detail label="Field Name" :value="value" />
 *
 * Or a `value` slot:
 *
 * <runner-detail label="Field Name">
 *   <template #value>
 *     <strong>{{ value }}</strong>
 *   </template>
 * </runner-detail>
 *
 */
export default {
  props: {
    label: {
      type: String,
      default: null,
      required: false,
    },
    value: {
      type: String,
      default: null,
      required: false,
    },
    emptyValue: {
      type: String,
      default: __('None'),
      required: false,
    },
  },
};
</script>

<template>
  <div class="gl-contents">
    <dt class="gl-mb-5 gl-mr-6 gl-max-w-26" data-testid="label-slot">
      <template v-if="label || $scopedSlots.label">
        <slot name="label">{{ label }}</slot>
      </template>
    </dt>
    <dd class="gl-mb-5" data-testid="value-slot">
      <template v-if="value || $scopedSlots.value">
        <slot name="value">{{ value }}</slot>
      </template>
      <span v-else class="gl-text-subtle">{{ emptyValue }}</span>
    </dd>
  </div>
</template>
