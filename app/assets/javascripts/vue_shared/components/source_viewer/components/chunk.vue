<script>
import { GlIntersectionObserver, GlSafeHtmlDirective } from '@gitlab/ui';
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
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  props: {
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
    language: {
      type: String,
      required: false,
      default: null,
    },
  },
  computed: {
    lines() {
      return this.content.split('\n');
    },
  },
  methods: {
    handleChunkAppear() {
      if (!this.isHighlighted) {
        this.$emit('appear', this.chunkIndex);
      }
    },
  },
};
</script>
<template>
  <div>
    <gl-intersection-observer @appear="handleChunkAppear">
      <div v-if="isHighlighted">
        <chunk-line
          v-for="(line, index) in lines"
          :key="index"
          :number="startingFrom + index + 1"
          :content="line"
          :language="language"
        />
      </div>
      <div v-else class="gl-display-flex">
        <div class="gl-display-flex gl-flex-direction-column">
          <a
            v-for="(n, index) in totalLines"
            :id="`L${startingFrom + index + 1}`"
            :key="index"
            class="gl-ml-5 gl-text-transparent"
            :href="`#L${startingFrom + index + 1}`"
            :data-line-number="startingFrom + index + 1"
            data-testid="line-number"
          >
            {{ startingFrom + index + 1 }}
          </a>
        </div>
        <div
          class="gl-white-space-pre-wrap! gl-text-transparent"
          data-testid="content"
          v-text="content"
        ></div>
      </div>
    </gl-intersection-observer>
  </div>
</template>
