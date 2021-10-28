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
  },
};
</script>

<template>
  <div class="project-feature-row">
    <label v-if="label" class="label-bold">
      {{ label }}
    </label>
    <div>
      <span v-if="helpText" class="text-muted"> {{ helpText }} </span>
      <span v-if="helpPath"
        ><a :href="helpPath" target="_blank">{{ __('Learn more') }}</a
        >.</span
      >
    </div>
    <slot></slot>
  </div>
</template>
