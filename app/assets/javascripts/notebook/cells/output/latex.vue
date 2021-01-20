<script>
import 'mathjax/es5/tex-svg';
import Prompt from '../prompt.vue';

export default {
  name: 'LatexOutput',
  components: {
    Prompt,
  },
  props: {
    count: {
      type: Number,
      required: true,
    },
    rawCode: {
      type: String,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
  },
  computed: {
    code() {
      // MathJax will not parse out the inline delimeters "$$" correctly
      // so we remove them from the raw code itself
      const parsedCode = this.rawCode.replace(/\$\$/g, '');
      const svg = window.MathJax.tex2svg(parsedCode);

      // NOTE: This is used with `v-html` and not `v-safe-html` due to an
      // issue with dompurify stripping out xlink attributes from use tags
      return svg.outerHTML;
    },
  },
};
</script>

<template>
  <div class="output">
    <prompt type="Out" :count="count" :show-output="index === 0" />
    <!-- eslint-disable -->
    <div ref="maths" v-html="code"></div>
  </div>
</template>
