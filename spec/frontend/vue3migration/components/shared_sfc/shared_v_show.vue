<script>
// Intentionally has no imports: the infection scanner marks such a component as
// safe to share between the Vue 2 and the Vue 3 realm, so both extend this object.
export default {
  name: 'SharedVShow',
  props: {
    visible: {
      type: Boolean,
      required: true,
    },
  },
};
</script>
<template>
  <div>
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <span v-show="visible" data-testid="content">content</span>
  </div>
</template>
