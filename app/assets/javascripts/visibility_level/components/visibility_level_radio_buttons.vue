<script>
import { GlIcon, GlFormRadio, GlFormRadioGroup } from '@gitlab/ui';
import {
  VISIBILITY_LEVEL_LABELS,
  VISIBILITY_TYPE_ICON,
  VISIBILITY_LEVELS_INTEGER_TO_STRING,
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
  },
  computed: {
    visibilityLevelsOptions() {
      return this.visibilityLevels.map((visibilityLevel) => {
        const stringValue = VISIBILITY_LEVELS_INTEGER_TO_STRING[visibilityLevel];

        return {
          label: VISIBILITY_LEVEL_LABELS[stringValue],
          description: this.visibilityLevelDescriptions[stringValue],
          icon: VISIBILITY_TYPE_ICON[stringValue],
          value: visibilityLevel,
        };
      });
    },
  },
};
</script>

<template>
  <gl-form-radio-group :checked="checked" @input="$emit('input', $event)">
    <gl-form-radio
      v-for="{ label, description, icon, value } in visibilityLevelsOptions"
      :key="value"
      :value="value"
    >
      <div>
        <gl-icon :name="icon" />
        <span>{{ label }}</span>
      </div>
      <template #help>{{ description }}</template>
    </gl-form-radio>
  </gl-form-radio-group>
</template>
