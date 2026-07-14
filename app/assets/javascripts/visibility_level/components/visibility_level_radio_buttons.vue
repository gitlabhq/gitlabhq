<script>
import { GlIcon, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import { isNumber } from 'lodash-es';
import {
  VISIBILITY_LEVEL_LABELS,
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVELS_INTEGER_TO_STRING,
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
} from '~/visibility_level/constants';

export default {
  name: 'VisibilityLevelRadioButtons',
  components: {
    GlIcon,
    GlFormRadio,
    GlFormRadioGroup,
  },
  model: {
    prop: 'checked',
  },
  props: {
    checked: {
      type: Number,
      required: true,
    },
    visibilityLevels: {
      type: Array,
      required: true,
    },
    visibilityLevelDescriptions: {
      type: Object,
      required: true,
    },
    minVisibilityLevel: {
      type: Number,
      required: false,
      default: VISIBILITY_LEVEL_PRIVATE_INTEGER,
    },
  },
  emits: ['input'],
  computed: {
    visibilityLevelsOptions() {
      return this.visibilityLevels.map((visibilityLevel) => {
        const stringValue = VISIBILITY_LEVELS_INTEGER_TO_STRING[visibilityLevel];

        return {
          label: VISIBILITY_LEVEL_LABELS[stringValue],
          description: this.visibilityLevelDescriptions[stringValue],
          icon: VISIBILITY_TYPE_ICON[stringValue],
          value: visibilityLevel,
          disabled: isNumber(this.minVisibilityLevel)
            ? visibilityLevel < this.minVisibilityLevel
            : false,
        };
      });
    },
    hasDisabledVisibilityLevels() {
      return this.visibilityLevelsOptions.some((visibilityLevel) => visibilityLevel.disabled);
    },
  },
};
</script>

<template>
  <gl-form-radio-group :checked="checked" @input="$emit('input', $event)">
    <gl-form-radio
      v-for="{ label, description, icon, value, disabled } in visibilityLevelsOptions"
      :key="value"
      :value="value"
      :disabled="disabled"
    >
      <div>
        <gl-icon :name="icon" />
        <span>{{ label }}</span>
      </div>
      <template #help>{{ description }}</template>
    </gl-form-radio>
    <slot v-if="hasDisabledVisibilityLevels" name="disabled-message"></slot>
  </gl-form-radio-group>
</template>
