<script>
  import sanitize from 'sanitize-html';
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
    computed: {
      sanitizedOutput() {
        return sanitize(this.rawCode, {
          allowedTags: sanitize.defaults.allowedTags.concat([
            'img', 'svg',
          ]),
          allowedAttributes: {
            img: ['src'],
          },
        });
      },
    },
  };
</script>

<template>
  <div class="output">
    <prompt />
    <div v-html="sanitizedOutput"></div>
  </div>
</template>
