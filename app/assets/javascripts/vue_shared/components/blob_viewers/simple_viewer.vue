<script>
import { GlIcon } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { HIGHLIGHT_CLASS_NAME } from './constants';
import ViewerMixin from './mixins';

export default {
  name: 'SimpleViewer',
  components: {
    GlIcon,
  },
  directives: {
    SafeHtml,
  },
  mixins: [ViewerMixin],
  inject: ['blobHash'],
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
    if (hash) {
      this.scrollToLine(hash, true);
    }
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
  <div>
    <div class="file-content code js-syntax-highlight" :class="$options.userColorScheme">
      <div v-if="!hideLineNumbers" class="line-numbers gl-pt-0!">
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
        <pre
          class="code highlight gl-p-0! gl-display-flex"
        ><code v-safe-html="content" :data-blob-hash="blobHash"></code></pre>
      </div>
    </div>
  </div>
</template>
