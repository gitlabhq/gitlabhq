<script>
import SafeHtml from '~/vue_shared/directives/safe_html';
import Blame from '../source_viewer/components/blame_info.vue';
import { calculateBlameOffset, shouldRender, toggleBlameClasses } from '../source_viewer/utils';
import blameDataQuery from '../source_viewer/queries/blame_data.query.graphql';
import ViewerMixin from './mixins';
import { HIGHLIGHT_CLASS_NAME, MAX_BLAME_LINES } from './constants';

export default {
  name: 'SimpleViewer',
  components: {
    Blame,
  },
  directives: {
    SafeHtml,
  },
  mixins: [ViewerMixin],
  inject: ['blobHash'],
  props: {
    blobPath: {
      type: String,
      required: true,
    },
    showBlame: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBlameLinkHidden: {
      type: Boolean,
      required: false,
      default: false,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
    lineNumbers: {
      type: Number,
      required: true,
    },
    currentRef: {
      type: String,
      required: false,
      default: '',
    },
    blamePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      highlightedLine: null,
      blameData: [],
      fromLine: 1,
      toLine: MAX_BLAME_LINES,
    };
  },
  computed: {
    showBlameLink() {
      return !this.isBlameLinkHidden && !this.showBlame;
    },
    blameInfoForRange() {
      return this.blameData.reduce((result, blame, index) => {
        if (shouldRender(this.blameData, index)) {
          result.push({
            ...blame,
            blameOffset: calculateBlameOffset(blame.lineno, index),
          });
        }

        return result;
      }, []);
    },
  },
  watch: {
    showBlame: {
      handler(isVisible) {
        toggleBlameClasses(this.blameData, isVisible);
        this.requestBlameInfo(this.fromLine, this.toLine);
      },
      immediate: true,
    },
    blameData: {
      handler(blameData) {
        if (!this.showBlame) return;
        toggleBlameClasses(blameData, true);
      },
      immediate: true,
    },
  },
  mounted() {
    const { hash } = window.location;
    if (hash) {
      this.scrollToLine(hash, true);
    }
    this.toLine = this.lineNumbers <= MAX_BLAME_LINES ? this.lineNumbers : MAX_BLAME_LINES;
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
    async requestBlameInfo(fromLine, toLine) {
      if (!this.showBlame) return;

      const { data } = await this.$apollo.query({
        query: blameDataQuery,
        variables: {
          ref: this.currentRef,
          fullPath: this.projectPath,
          filePath: this.blobPath,
          fromLine,
          toLine,
        },
      });

      const blob = data?.project?.repository?.blobs?.nodes[0];
      const blameGroups = blob?.blame?.groups;
      const isDuplicate = this.blameData.includes(blameGroups[0]);
      if (blameGroups && !isDuplicate) this.blameData.push(...blameGroups);
      if (this.toLine < this.lineNumbers) {
        this.fromLine += MAX_BLAME_LINES;
        this.toLine += MAX_BLAME_LINES;
        this.requestBlameInfo(this.fromLine, this.toLine);
      }
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>
<template>
  <div>
    <div class="file-content code js-syntax-highlight gl-flex" :class="$options.userColorScheme">
      <blame v-if="showBlame && blameInfoForRange.length" :blame-info="blameInfoForRange" />
      <div class="line-numbers !gl-px-0">
        <div v-for="line in lineNumbers" :key="line" class="diff-line-num line-links gl-flex">
          <a
            v-if="showBlameLink"
            class="file-line-blame -gl-mx-2 gl-select-none !gl-shadow-none"
            :href="`${blamePath}#L${line}`"
          ></a>
          <a
            :id="`L${line}`"
            :key="line"
            class="file-line-num gl-select-none !gl-shadow-none"
            :href="`#L${line}`"
            :data-line-number="line"
            @click="scrollToLine(`#LC${line}`)"
          >
            {{ line }}
          </a>
        </div>
      </div>
      <div class="blob-content gl-flex gl-w-full gl-flex-col gl-overflow-y-auto">
        <pre
          class="code highlight !gl-p-0"
        ><code v-safe-html="content" :data-blob-hash="blobHash"></code></pre>
      </div>
    </div>
  </div>
</template>
