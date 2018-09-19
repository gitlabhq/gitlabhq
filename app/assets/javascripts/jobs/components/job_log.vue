<script>
  export default {
    name: 'JobLog',
    props: {
      trace: {
        type: String,
        required: true,
      },
      isReceivingBuildTrace: {
        type: Boolean,
        required: true,
      },
    },
  };
</script>
<template>
  <pre class="build-trace">
    <code
      class="bash"
      v-html="trace"
    >
    </code>

    <div
      v-if="isReceivingBuildTrace"
      class="js-log-animation build-loader-animation"
    >
      <div class="dot"></div>
      <div class="dot"></div>
      <div class="dot"></div>
    </div>
  </pre>
</template>
