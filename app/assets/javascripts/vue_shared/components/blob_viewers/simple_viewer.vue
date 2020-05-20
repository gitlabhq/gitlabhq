<script>
import ViewerMixin from './mixins';
import { GlIcon } from '@gitlab/ui';
import { HIGHLIGHT_CLASS_NAME } from './constants';

export default {
  components: {
    GlIcon,
  },
  mixins: [ViewerMixin],
  data() {
    return {
      highlightedLine: null,
    };
  },
  computed: {
    lineNumbers() {
      return this.content.split('\n').length;
    },
  },
  mounted() {
    const { hash } = window.location;
    if (hash) this.scrollToLine(hash, true);
  },
  methods: {
    scrollToLine(hash, scroll = false) {
      const lineToHighlight = hash && this.$el.querySelector(hash);
      const currentlyHighlighted = this.highlightedLine;
      if (lineToHighlight) {
        if (currentlyHighlighted) {
          currentlyHighlighted.classList.remove(HIGHLIGHT_CLASS_NAME);
        }

        lineToHighlight.classList.add(HIGHLIGHT_CLASS_NAME);
        this.highlightedLine = lineToHighlight;
        if (scroll) {
          lineToHighlight.scrollIntoView({ behavior: 'smooth', block: 'center' });
        }
      }
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>
<template>
  <div
    class="file-content code js-syntax-highlight"
    data-qa-selector="file_content"
    :class="$options.userColorScheme"
  >
    <div class="line-numbers">
      <a
        v-for="line in lineNumbers"
        :id="`L${line}`"
        :key="line"
        class="diff-line-num js-line-number"
        :href="`#LC${line}`"
        :data-line-number="line"
        @click="scrollToLine(`#LC${line}`)"
      >
        <gl-icon :size="12" name="link" />
        {{ line }}
      </a>
    </div>
    <div class="blob-content">
      <pre class="code highlight"><code id="blob-code-content" v-html="content"></code></pre>
    </div>
  </div>
</template>
