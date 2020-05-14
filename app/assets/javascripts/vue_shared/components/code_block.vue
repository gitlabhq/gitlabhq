<script>
export default {
  name: 'CodeBlock',
  props: {
    code: {
      type: String,
      required: true,
    },
    maxHeight: {
      type: String,
      required: false,
      default: 'initial',
    },
  },
  computed: {
    styleObject() {
      const { maxHeight } = this;
      const isScrollable = maxHeight !== 'initial';
      const scrollableStyles = {
        maxHeight,
        overflowY: 'auto',
      };

      return isScrollable ? scrollableStyles : null;
    },
  },
};
</script>
<template>
  <pre class="code-block rounded" :style="styleObject"><code class="d-block">{{ code }}</code></pre>
</template>
