<script>
export default {
  name: 'CodeBlock',
  props: {
    code: {
      type: String,
      required: true,
    },
  },
};
</script>
<template>
  <pre class="code-block rounded">
    <code class="d-block">{{ code }}</code>
  </pre>
</template>
