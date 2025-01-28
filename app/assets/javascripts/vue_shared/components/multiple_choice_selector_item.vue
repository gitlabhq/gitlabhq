<script>
import { GlFormCheckbox } from '@gitlab/ui';

export default {
  components: { GlFormCheckbox },
  props: {
    value: {
      type: String,
      required: false,
      default: null,
    },
    title: {
      type: String,
      required: false,
      default: null,
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    disabledMessage: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div class="multiple-choice-selector-item gl-p-5" :class="{ 'gl-bg-disabled': disabled }">
    <gl-form-checkbox :value="value" :disabled="disabled">
      <div class="multiple-choice-selector-click-area"></div>
      <div
        class="multiple-choice-selector-item-title gl-flex gl-flex-wrap gl-items-center gl-gap-3 gl-font-bold"
      >
        <slot>
          {{ title }}
        </slot>
      </div>
      <p v-if="disabled && disabledMessage" class="help-text !gl-text-warning">
        {{ disabledMessage }}
      </p>
      <p v-if="description" class="help-text">
        {{ description }}
      </p>
    </gl-form-checkbox>
  </div>
</template>
