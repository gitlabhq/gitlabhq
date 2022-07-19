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
      required: true,
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
  <div class="gl-display-flex gl-pb-4">
    <dt class="gl-mr-2">{{ label }}</dt>
    <dd class="gl-mb-0">
      <!-- eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots -->
      <template v-if="value || $slots.value">
        <slot name="value">{{ value }}</slot>
      </template>
      <span v-else class="gl-text-gray-500">{{ emptyValue }}</span>
    </dd>
  </div>
</template>
