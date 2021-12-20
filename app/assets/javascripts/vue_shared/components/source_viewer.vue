<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import LineNumbers from '~/vue_shared/components/line_numbers.vue';

export default {
  components: {
    LineNumbers,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    content: {
      type: String,
      required: true,
    },
    language: {
      type: String,
      required: false,
      default: 'plaintext',
    },
    autoDetect: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      languageDefinition: null,
      hljs: null,
    };
  },
  computed: {
    lineNumbers() {
      return this.content.split('\n').length;
    },
    highlightedContent() {
      let highlightedContent;

      if (this.hljs) {
        if (this.autoDetect) {
          highlightedContent = this.hljs.highlightAuto(this.content).value;
        } else if (this.languageDefinition) {
          highlightedContent = this.hljs.highlight(this.content, { language: this.language }).value;
        }
      }

      return highlightedContent;
    },
  },
  async mounted() {
    this.hljs = await this.loadHighlightJS();

    if (!this.autoDetect) {
      this.languageDefinition = await this.loadLanguage();
    }
  },
  methods: {
    loadHighlightJS() {
      // With auto-detect enabled we load all common languages else we load only the core (smallest footprint)
      return this.autoDetect ? import('highlight.js/lib/common') : import('highlight.js/lib/core');
    },
    async loadLanguage() {
      let languageDefinition;

      try {
        languageDefinition = await import(`highlight.js/lib/languages/${this.language}`);
        this.hljs.registerLanguage(this.language, languageDefinition.default);
      } catch (message) {
        this.$emit('error', message);
      }

      return languageDefinition;
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>
<template>
  <div class="file-content code" :class="$options.userColorScheme">
    <line-numbers :lines="lineNumbers" />
    <pre
      class="code gl-pl-3!"
    ><code v-safe-html="highlightedContent" class="gl-white-space-pre-wrap!"></code>
    </pre>
  </div>
</template>
