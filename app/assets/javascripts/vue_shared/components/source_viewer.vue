<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import LineNumbers from '~/vue_shared/components/line_numbers.vue';
import { sanitize } from '~/lib/dompurify';

const LINE_SELECT_CLASS_NAME = 'hll';
const PLAIN_TEXT_LANGUAGE = 'plaintext';

export default {
  components: {
    LineNumbers,
  },
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
    blob: {
      type: Object,
      required: true,
    },
    autoDetect: {
      type: Boolean,
      required: false,
      default: true, // We'll eventually disable autoDetect and pass the language explicitly to reduce the footprint (https://gitlab.com/gitlab-org/gitlab/-/issues/348145)
    },
  },
  data() {
    return {
      languageDefinition: null,
      content: this.blob.rawTextBlob,
      language: this.blob.language || PLAIN_TEXT_LANGUAGE,
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
    $route() {
      this.selectLine();
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
  <div
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
