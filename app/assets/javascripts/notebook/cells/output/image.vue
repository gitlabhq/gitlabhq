<script>
  import Prompt from '../prompt.vue';

  export default {
    components: {
      prompt: Prompt,
    },
    props: {
      outputType: {
        type: String,
        required: true,
      },
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
    <img :src="'data:' + outputType + ';base64,' + rawCode" />
  </div>
</template>
