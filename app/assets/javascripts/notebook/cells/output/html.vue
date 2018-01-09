<script>
<<<<<<< HEAD
  import Prompt from '../prompt.vue';
=======
import sanitize from 'sanitize-html';
import Prompt from '../prompt.vue';
>>>>>>> Merge branch 'fl-ipythin-10-3' into 'security-10-3'

  export default {
    components: {
      prompt: Prompt,
    },
<<<<<<< HEAD
    props: {
      rawCode: {
        type: String,
        required: true,
      },
    },
  };
=======
  },
  components: {
    prompt: Prompt,
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
>>>>>>> Merge branch 'fl-ipythin-10-3' into 'security-10-3'
</script>

<template>
  <div class="output">
    <prompt />
    <div v-html="sanitizedOutput"></div>
  </div>
</template>
