<script>
import Prism from '../../lib/highlight';
import Prompt from '../prompt.vue';

export default {
  name: 'CodeOutput',
  components: {
    Prompt,
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
    metadata: {
      type: Object,
      default: () => ({}),
      required: false,
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
    cellCssClass() {
      return {
        [this.codeCssClass]: true,
        'jupyter-notebook-scrolled': this.metadata.scrolled,
      };
    },
  },
  mounted() {
    Prism.highlightElement(this.$refs.code);
  },
};
</script>

<template>
  <div :class="type">
    <prompt :type="promptType" :count="count" />
    <pre ref="code" :class="cellCssClass" class="language-python" v-text="code"></pre>
  </div>
</template>
