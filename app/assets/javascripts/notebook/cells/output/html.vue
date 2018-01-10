<script>
  import Prompt from '../prompt.vue';

  export default {
    components: {
      prompt: Prompt,
    },
    props: {
      rawCode: {
        type: String,
        required: true,
      },
    },
  };
</script>

<template>
  <div class="output">
    <prompt />
    <div v-html="rawCode"></div>
  </div>
</template>
