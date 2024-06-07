<script>
export default {
  name: 'CodeBlock',
  props: {
    code: {
      type: String,
      required: false,
      default: '',
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
  userColorScheme: window.gon.user_color_scheme,
};
</script>
<template>
  <pre
    class="code-block rounded code"
    :class="$options.userColorScheme"
    :style="styleObject"
  ><slot><code class="gl-block">{{ code }}</code></slot></pre>
</template>
