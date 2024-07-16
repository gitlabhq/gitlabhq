<script>
import { GlIntersectionObserver } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getPageParamValue, getPageSearchString } from '~/blob/utils';

/*
 * We only highlight the chunk that is currently visible to the user.
 * By making use of the Intersection Observer API we can determine when a chunk becomes visible and highlight it accordingly.
 *
 * Content that is not visible to the user (i.e. not highlighted) does not need to look nice,
 * so by rendering raw (non-highlighted) text, the browser spends less resources on painting
 * content that is not immediately relevant.
 * Why use plaintext as opposed to hiding content entirely?
 * If content is hidden entirely, native find text (⌘ + F) won't work.
 */
export default {
  components: {
    GlIntersectionObserver,
  },
  directives: {
    SafeHtml,
  },
  props: {
    isHighlighted: {
      type: Boolean,
      required: true,
    },
    chunkIndex: {
      type: Number,
      required: false,
      default: 0,
    },
    rawContent: {
      type: String,
      required: true,
    },
    highlightedContent: {
      type: String,
      required: true,
    },
    totalLines: {
      type: Number,
      required: false,
      default: 0,
    },
    startingFrom: {
      type: Number,
      required: false,
      default: 0,
    },
    blamePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hasAppeared: false,
    };
  },
  computed: {
    shouldHighlight() {
      return Boolean(this.highlightedContent) && (this.hasAppeared || this.isHighlighted);
    },
    pageSearchString() {
      const page = getPageParamValue(this.number);
      return getPageSearchString(this.blamePath, page);
    },
    codeStyling() {
      const defaultGutterWidth = 96;
      return { marginLeft: `${this.$refs.lineNumbers?.offsetWidth || defaultGutterWidth}px` };
    },
  },
  methods: {
    handleChunkAppear() {
      this.hasAppeared = true;
      this.$emit('appear');
    },
    calculateLineNumber(index) {
      return this.startingFrom + index + 1;
    },
  },
};
</script>
<template>
  <div class="gl-display-flex">
    <div v-if="shouldHighlight" class="gl-display-flex gl-flex-direction-column gl-absolute">
      <div
        v-for="(n, index) in totalLines"
        :key="index"
        data-testid="line-numbers"
        class="gl-p-0! gl-z-3 diff-line-num gl-border-r gl-display-flex line-links line-numbers"
      >
        <a
          class="gl-select-none !gl-shadow-none file-line-blame"
          data-event-tracking="click_chunk_blame_on_blob_page"
          :href="`${blamePath}${pageSearchString}#L${calculateLineNumber(index)}`"
        ></a>
        <a
          :id="`L${calculateLineNumber(index)}`"
          class="gl-select-none !gl-shadow-none file-line-num"
          :href="`#L${calculateLineNumber(index)}`"
          :data-line-number="calculateLineNumber(index)"
        >
          {{ calculateLineNumber(index) }}
        </a>
      </div>
    </div>

    <div v-else ref="lineNumbers" class="line-numbers gl-p-0! gl-mr-3 gl-text-transparent">
      <!-- Placeholder for line numbers while content is not highlighted -->
    </div>

    <gl-intersection-observer class="gl-w-full" @appear="handleChunkAppear">
      <pre
        class="gl-m-0 gl-p-0! gl-w-full gl-overflow-visible! gl-border-none! code highlight gl-leading-0"
      ><code v-if="shouldHighlight" v-safe-html="highlightedContent" :style="codeStyling" data-testid="content"></code><code v-else v-once class="line !gl-whitespace-pre-wrap gl-ml-1" data-testid="content" v-text="rawContent"></code></pre>
    </gl-intersection-observer>
  </div>
</template>
