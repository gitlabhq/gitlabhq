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
    <label
      v-if="label"
      class="label-light"
    >
      {{ label }}
      <a
        v-if="helpPath"
        :href="helpPath"
        target="_blank"
      >
        <i
          aria-hidden="true"
          data-hidden="true"
          class="fa fa-question-circle"
        >
        </i>
      </a>
    </label>
    <span
      v-if="helpText"
      class="help-block"
    >
      {{ helpText }}
    </span>
    <slot></slot>
  </div>
</template>
