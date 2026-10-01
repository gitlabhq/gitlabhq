<script>
// No imports; declares its own directive.
export default {
  name: 'SharedLocalDirective',
  directives: {
    mark: {
      mounted(el) {
        el.dataset.marked = 'yes';
      },
    },
  },
};
</script>
<template>
  <div>
    <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
    <span v-mark data-testid="content">content</span>
  </div>
</template>
