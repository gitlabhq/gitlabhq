<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import 'mathjax/es5/tex-svg';
import Prompt from '../prompt.vue';

export default {
  name: 'LatexOutput',
  components: {
    Prompt,
  },
  directives: {
    SafeHtml,
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
  safeHtmlConfig: {
    // to support SVGs and custom tags for mathjax
    ADD_TAGS: ['use', 'mjx-container', 'mjx-tool', 'mjx-status', 'mjx-tip'],
  },
};
</script>

<template>
  <div class="output">
    <prompt type="Out" :count="count" :show-output="index === 0" />
    <div ref="maths" v-safe-html:[$options.safeHtmlConfig]="code"></div>
  </div>
</template>
