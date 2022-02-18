<script>
import { GlSafeHtmlDirective, GlLoadingIcon } from '@gitlab/ui';
import LineNumbers from '~/vue_shared/components/line_numbers.vue';
import { sanitize } from '~/lib/dompurify';
import { ROUGE_TO_HLJS_LANGUAGE_MAP } from './constants';
import { wrapLines } from './utils';

const LINE_SELECT_CLASS_NAME = 'hll';

export default {
  components: {
    LineNumbers,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      languageDefinition: null,
      content: this.blob.rawTextBlob,
      language: ROUGE_TO_HLJS_LANGUAGE_MAP[this.blob.language],
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
        if (!this.language) {
          highlightedContent = this.hljs.highlightAuto(this.content).value;
        } else if (this.languageDefinition) {
          highlightedContent = this.hljs.highlight(this.content, { language: this.language }).value;
        }
      }

      return wrapLines(highlightedContent);
    },
  },
  watch: {
    highlightedContent() {
      this.$nextTick(() => this.selectLine());
    },
    $route() {
      this.selectLine();
    },
  },
  async mounted() {
    this.hljs = await this.loadHighlightJS();

    if (this.language) {
      this.languageDefinition = await this.loadLanguage();
    }
  },
  methods: {
    loadHighlightJS() {
      // If no language can be mapped to highlight.js we load all common languages else we load only the core (smallest footprint)
      return !this.language ? import('highlight.js/lib/common') : import('highlight.js/lib/core');
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
    selectLine() {
      const hash = sanitize(this.$route.hash);
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
  <gl-loading-icon v-if="!highlightedContent" size="sm" class="gl-my-5" />
  <div
    v-else
    class="file-content code js-syntax-highlight blob-content gl-display-flex"
    :class="$options.userColorScheme"
    data-type="simple"
    data-qa-selector="blob_viewer_file_content"
  >
    <line-numbers :lines="lineNumbers" />
    <pre class="code gl-pb-0!"><code v-safe-html="highlightedContent"></code>
    </pre>
  </div>
</template>
