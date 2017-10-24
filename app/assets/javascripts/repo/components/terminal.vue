<script>
  export default {
    props: {
      endpoint: {
        type: String,
        required: true,
      },
    },
    mounted() {
      return new gl.Terminal({
        selector: '#terminal',
      });
    },
  };
</script>

<template>
  <div id="terminal" :data-project-path="endpoint"></div>
</template>
