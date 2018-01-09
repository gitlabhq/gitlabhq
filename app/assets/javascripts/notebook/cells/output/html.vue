<script>
<<<<<<< HEAD
  import Prompt from '../prompt.vue';
||||||| parent of 1c46e031c7... Merge branch 'fl-ipythin-10-3' into 'security-10-3'
import Prompt from '../prompt.vue';
=======
import sanitize from 'sanitize-html';
import Prompt from '../prompt.vue';
>>>>>>> 1c46e031c7... Merge branch 'fl-ipythin-10-3' into 'security-10-3'

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
||||||| parent of 1c46e031c7... Merge branch 'fl-ipythin-10-3' into 'security-10-3'
  },
  components: {
    prompt: Prompt,
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
>>>>>>> 1c46e031c7... Merge branch 'fl-ipythin-10-3' into 'security-10-3'
</script>

<template>
  <div class="output">
    <prompt />
    <div v-html="sanitizedOutput"></div>
  </div>
</template>
