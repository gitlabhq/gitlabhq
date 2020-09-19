<script>
import { GlIcon } from '@gitlab/ui';

export default {
  components: {
    GlIcon,
  },
  props: {
    label: {
      type: String,
      required: false,
      default: null,
    },
    helpPath: {
      type: String,
      required: false,
      default: null,
    },
    helpText: {
      type: String,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div class="project-feature-row">
    <label v-if="label" class="label-bold">
      {{ label }}
      <a v-if="helpPath" :href="helpPath" target="_blank">
        <gl-icon name="question-o" />
      </a>
    </label>
    <span v-if="helpText" class="form-text text-muted"> {{ helpText }} </span> <slot></slot>
  </div>
</template>
