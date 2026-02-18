<script>
export default {
  name: 'DynamicComponent',
  props: {
    as: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
  <component :is="as" data-testid="dynamic">dynamic content</component>
</template>
