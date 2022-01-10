<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import LineNumbers from '~/vue_shared/components/line_numbers.vue';
import { sanitize } from '~/lib/dompurify';
import '~/sourcegraph/load';

const LINE_SELECT_CLASS_NAME = 'hll';

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

      return this.wrapLines(highlightedContent);
    },
  },
  watch: {
    highlightedContent() {
      this.$nextTick(() => this.selectLine());
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
    wrapLines(content) {
      return (
        content &&
        content
          .split('\n')
          .map((line, i) => `<span id="LC${i + 1}" class="line">${line}</span>`)
          .join('\r\n')
      );
    },
    selectLine(hash = sanitize(window.location.hash)) {
      const lineToSelect = hash && this.$el.querySelector(hash);

      if (!lineToSelect) {
        return;
      }

      if (this.$options.currentlySelectedLine) {
        this.$options.currentlySelectedLine.classList.remove(LINE_SELECT_CLASS_NAME);
      }

      lineToSelect.classList.add(LINE_SELECT_CLASS_NAME);
      this.$options.currentlySelectedLine = lineToSelect;
      lineToSelect.scrollIntoView({ behavior: 'smooth', block: 'center' });
    },
  },
  userColorScheme: window.gon.user_color_scheme,
  currentlySelectedLine: null,
};
</script>
<template>
  <div class="file-content code" :class="$options.userColorScheme">
    <line-numbers :lines="lineNumbers" @select-line="selectLine" />
    <pre class="code"><code v-safe-html="highlightedContent"></code>
    </pre>
  </div>
</template>
