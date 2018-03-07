<script>
  import Prism from '../../lib/highlight';
  import Prompt from '../prompt.vue';

  export default {
    components: {
      prompt: Prompt,
    },
    props: {
      count: {
        type: Number,
        required: false,
        default: 0,
      },
      codeCssClass: {
        type: String,
        required: false,
        default: '',
      },
      type: {
        type: String,
        required: true,
      },
      rawCode: {
        type: String,
        required: true,
      },
    },
    computed: {
      code() {
        return this.rawCode;
      },
      promptType() {
        const type = this.type.split('put')[0];

        return type.charAt(0).toUpperCase() + type.slice(1);
      },
    },
    mounted() {
      Prism.highlightElement(this.$refs.code);
    },
  };
</script>

<template>
  <div :class="type">
    <prompt
      :type="promptType"
      :count="count" />
    <pre
      class="language-python"
      :class="codeCssClass"
      ref="code"
      v-text="code">
    </pre>
  </div>
</template>
