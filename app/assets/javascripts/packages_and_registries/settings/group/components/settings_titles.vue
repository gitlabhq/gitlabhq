<script>
export default {
  name: 'SettingsTitle',
  props: {
    title: {
      type: String,
      required: true,
    },
    subTitle: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <div>
    <h5 class="gl-border-b-solid gl-border-b-1 gl-border-gray-200 gl-pb-3">
      {{ title }}
    </h5>
    <p v-if="subTitle">{{ subTitle }}</p>
    <slot></slot>
  </div>
</template>
