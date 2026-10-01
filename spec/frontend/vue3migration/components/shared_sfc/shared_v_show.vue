<script>
// No imports, so the infection scanner shares this file between both realms.
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
