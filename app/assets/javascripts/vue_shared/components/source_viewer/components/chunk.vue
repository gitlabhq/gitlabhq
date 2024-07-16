<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlIntersectionObserver } from '@gitlab/ui';
import LineHighlighter from '~/blob/line_highlighter';
import ChunkLine from './chunk_line.vue';

/*
 * We only highlight the chunk that is currently visible to the user.
 * By making use of the Intersection Observer API we can determine when a chunk becomes visible and highlight it accordingly.
 *
 * Content that is not visible to the user (i.e. not highlighted) do not need to look nice,
 * so by making text transparent and rendering raw (non-highlighted) text,
 * the browser spends less resources on painting content that is not immediately relevant.
 *
 * Why use transparent text as opposed to hiding content entirely?
 * 1. If content is hidden entirely, native find text (⌘ + F) won't work.
 * 2. When URL contains line numbers, the browser needs to be able to jump to the correct line.
 */
export default {
  components: {
    ChunkLine,
    GlIntersectionObserver,
  },
  props: {
    isFirstChunk: {
      type: Boolean,
      required: false,
      default: false,
    },
    chunkIndex: {
      type: Number,
      required: false,
      default: 0,
    },
    isHighlighted: {
      type: Boolean,
      required: true,
    },
    content: {
      type: String,
      required: true,
    },
    startingFrom: {
      type: Number,
      required: false,
      default: 0,
    },
    totalLines: {
      type: Number,
      required: false,
      default: 0,
    },
    totalChunks: {
      type: Number,
      required: false,
      default: 0,
    },
    language: {
      type: String,
      required: false,
      default: null,
    },
    blamePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isLoading: true,
    };
  },
  computed: {
    lines() {
      return this.content.split('\n');
    },
  },

  created() {
    if (this.isFirstChunk) {
      this.isLoading = false;
      return;
    }

    window.requestIdleCallback(async () => {
      this.isLoading = false;
      const { hash } = this.$route;
      if (hash && this.totalChunks > 0 && this.totalChunks === this.chunkIndex + 1) {
        // when the last chunk is loaded scroll to the hash
        await this.$nextTick();
        const lineHighlighter = new LineHighlighter({ scrollBehavior: 'auto' });
        lineHighlighter.highlightHash(hash);
      }
    });
  },
  methods: {
    handleChunkAppear() {
      if (!this.isHighlighted) {
        this.$emit('appear', this.chunkIndex);
      }
    },
    calculateLineNumber(index) {
      return this.startingFrom + index + 1;
    },
  },
};
</script>
<template>
  <gl-intersection-observer @appear="handleChunkAppear">
    <div v-if="isHighlighted">
      <chunk-line
        v-for="(line, index) in lines"
        :key="index"
        :number="calculateLineNumber(index)"
        :content="line"
        :language="language"
        :blame-path="blamePath"
      />
    </div>
    <div v-else-if="!isLoading" class="gl-display-flex gl-text-transparent">
      <div class="gl-display-flex gl-flex-direction-column content-visibility-auto">
        <span
          v-for="(n, index) in totalLines"
          v-once
          :id="`L${calculateLineNumber(index)}`"
          :key="index"
          data-testid="line-number"
          v-text="calculateLineNumber(index)"
        ></span>
      </div>
      <div v-once class="gl-whitespace-pre-wrap!" data-testid="content">{{ content }}</div>
    </div>
  </gl-intersection-observer>
</template>
