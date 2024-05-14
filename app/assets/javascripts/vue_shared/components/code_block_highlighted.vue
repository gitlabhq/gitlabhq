<script>
import { escape } from 'lodash';
import SafeHtml from '~/vue_shared/directives/safe_html';
import languageLoader from '~/content_editor/services/highlight_js_language_loader';
import CodeBlock from './code_block.vue';

export default {
  name: 'CodeBlockHighlighted',
  directives: {
    SafeHtml,
  },
  components: {
    CodeBlock,
  },
  props: {
    code: {
      type: String,
      required: true,
    },
    language: {
      type: String,
      required: true,
    },
    maxHeight: {
      type: String,
      required: false,
      default: 'initial',
    },
  },
  data() {
    return {
      hljs: null,
      languageLoaded: false,
    };
  },
  computed: {
    highlighted() {
      if (this.hljs && this.languageLoaded) {
        return this.hljs.default.highlight(this.code, { language: this.language }).value;
      }

      return escape(this.code);
    },
  },
  async mounted() {
    this.hljs = await this.loadHighlightJS();
    if (this.language) {
      await this.loadLanguage();
    }
  },
  methods: {
    async loadLanguage() {
      try {
        const { default: languageDefinition } = await languageLoader[this.language]();

        this.hljs.default.registerLanguage(this.language, languageDefinition);
        this.languageLoaded = true;
      } catch (e) {
        this.$emit('error', e);
      }
    },
    loadHighlightJS() {
      return import('highlight.js/lib/core');
    },
  },
};
</script>
<template>
  <code-block :max-height="maxHeight" class="highlight">
    <span v-safe-html="highlighted"></span>
  </code-block>
</template>
