<script>
const calloutVariants = ['danger', 'success', 'info', 'warning'];

export default {
  props: {
    category: {
      type: String,
      required: false,
      default: calloutVariants[0],
      validator: value => calloutVariants.includes(value),
    },
    message: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>
<template>
  <div :class="`bs-callout bs-callout-${category}`" role="alert" aria-live="assertive">
    {{ message }} <slot></slot>
  </div>
</template>
