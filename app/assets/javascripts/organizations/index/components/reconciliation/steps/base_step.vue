<script>
export default {
  name: 'ReconciliationBaseStep',
  props: {
    illustration: {
      type: String,
      required: false,
      default: '',
    },
    title: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div>
    <div class="gl-mb-8 gl-text-center">
      <img v-if="illustration" :src="illustration" aria-hidden="true" class="gl-my-4 gl-max-w-20" />
      <h2 v-if="title" class="gl-heading-2">{{ title }}</h2>
      <div class="gl-mx-auto gl-w-full gl-max-w-md">
        <slot name="description"></slot>
      </div>
    </div>
    <slot></slot>
  </div>
</template>
