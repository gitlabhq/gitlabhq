<!-- eslint-disable vue/multi-word-component-names -->
<script>
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import { GlIntersectionObserver } from '@gitlab/ui';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { getPageParamValue, getPageSearchString } from '~/blob/utils';
import { addInteractionClass } from '~/code_navigation/utils';

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
    blobPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      number: undefined,
      hasAppeared: false,
    };
  },
  computed: {
    ...mapState(['data', 'blobs']),
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
  watch: {
    shouldHighlight: {
      handler(newVal) {
        if (!this.blobs?.length) return;

        if (newVal) {
          if (this.data) {
            this.addCodeNavigationClasses();
          } else {
            // If there the code navigation hasn't loaded yet we need to watch
            // for the data to be set in the state
            this.codeNavigationDataWatcher = this.$watch('data', () => {
              this.addCodeNavigationClasses();
              this.codeNavigationDataWatcher();
            });
          }
        }
      },
      immediate: true,
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
    async addCodeNavigationClasses() {
      await this.$nextTick();

      Object.keys(this.data[this.blobPath]).forEach((key) => {
        const startLine = Number(key.split(':')[0]);

        if (startLine >= this.startingFrom && startLine < this.startingFrom + this.totalLines + 1) {
          addInteractionClass({
            path: this.blobPath,
            d: this.data[this.blobPath][key],
          });
        }
      });
    },
  },
};
</script>
<template>
  <div class="gl-flex">
    <div v-if="shouldHighlight" class="gl-absolute gl-flex gl-flex-col">
      <div
        v-for="(n, index) in totalLines"
        :key="index"
        data-testid="line-numbers"
        class="diff-line-num line-links line-numbers gl-border-r gl-z-3 gl-flex !gl-p-0"
      >
        <a
          class="file-line-blame gl-select-none !gl-shadow-none"
          data-event-tracking="click_chunk_blame_on_blob_page"
          :href="`${blamePath}${pageSearchString}#L${calculateLineNumber(index)}`"
        ></a>
        <a
          :id="`L${calculateLineNumber(index)}`"
          class="file-line-num gl-select-none !gl-shadow-none"
          :href="`#L${calculateLineNumber(index)}`"
          :data-line-number="calculateLineNumber(index)"
        >
          {{ calculateLineNumber(index) }}
        </a>
      </div>
    </div>

    <div v-else ref="lineNumbers" class="line-numbers gl-mr-3 !gl-p-0 gl-text-transparent">
      <!-- Placeholder for line numbers while content is not highlighted -->
    </div>

    <gl-intersection-observer class="gl-w-full" @appear="handleChunkAppear">
      <pre
        class="code highlight gl-m-0 gl-w-full !gl-overflow-visible !gl-border-none !gl-p-0 gl-leading-0"
      ><code v-if="shouldHighlight" v-safe-html="highlightedContent" :style="codeStyling" data-testid="content"></code><code v-else v-once class="line !gl-whitespace-pre-wrap gl-ml-1" data-testid="content" v-text="rawContent"></code></pre>
    </gl-intersection-observer>
  </div>
</template>
