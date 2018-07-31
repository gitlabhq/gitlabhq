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
  <pre class="code-block build-trace-rounded">
    <code class="bash">{{ code }}</code>
  </pre>
</template>
