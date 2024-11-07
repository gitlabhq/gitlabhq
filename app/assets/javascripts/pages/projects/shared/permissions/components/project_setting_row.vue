<script>
export default {
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
    locked: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="project-feature-row">
    <div class="gl-flex">
      <label v-if="label" class="label-bold !gl-mb-0" :class="{ 'gl-text-disabled': locked }">
        {{ label }}
      </label>
      <slot name="label-icon"></slot>
    </div>
    <div>
      <span v-if="helpText" class="gl-text-subtle"> {{ helpText }} </span>
      <span v-if="helpPath"
        ><a :href="helpPath" target="_blank">{{ __('Learn more') }}</a
        >.</span
      >
    </div>
    <slot></slot>
  </div>
</template>
