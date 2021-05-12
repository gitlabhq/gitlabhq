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
      required: true,
    },
  },
};
</script>

<template>
  <div>
    <h5 class="gl-border-b-solid gl-border-b-1 gl-border-gray-200">
      {{ title }}
    </h5>
    <p>{{ subTitle }}</p>
    <slot></slot>
  </div>
</template>
