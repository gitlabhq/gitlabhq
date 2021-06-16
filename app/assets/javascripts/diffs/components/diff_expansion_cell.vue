<script>
import { GlIcon } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { UNFOLD_COUNT, INLINE_DIFF_VIEW_TYPE, INLINE_DIFF_LINES_KEY } from '../constants';
import * as utils from '../store/utils';

const EXPAND_ALL = 0;
const EXPAND_UP = 1;
const EXPAND_DOWN = 2;

const lineNumberByViewType = (viewType, diffLine) => {
  const numberGetters = {
    [INLINE_DIFF_VIEW_TYPE]: (line) => line?.new_line,
  };
  const numberGetter = numberGetters[viewType];
  return numberGetter && numberGetter(diffLine);
};

const i18n = {
  showMore: sprintf(s__('Diffs|Show %{unfoldCount} lines'), { unfoldCount: UNFOLD_COUNT }),
  showAll: s__('Diffs|Show all unchanged lines'),
};

export default {
  i18n,
  components: {
    GlIcon,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    fileHash: {
      type: String,
      required: true,
    },
    contextLinesPath: {
      type: String,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    isTop: {
      type: Boolean,
      required: false,
      default: false,
    },
    isBottom: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapState({
      diffFiles: (state) => state.diffs.diffFiles,
    }),
    canExpandUp() {
      return !this.isBottom;
    },
    canExpandDown() {
      return this.isBottom || !this.isTop;
    },
  },
  created() {
    this.EXPAND_DOWN = EXPAND_DOWN;
    this.EXPAND_UP = EXPAND_UP;
  },
  methods: {
    ...mapActions('diffs', ['loadMoreLines']),
    getPrevLineNumber(oldLineNumber, newLineNumber) {
      const diffFile = utils.findDiffFile(this.diffFiles, this.fileHash);
      const index = utils.getPreviousLineIndex(INLINE_DIFF_VIEW_TYPE, diffFile, {
        oldLineNumber,
        newLineNumber,
      });

      return (
        lineNumberByViewType(INLINE_DIFF_VIEW_TYPE, diffFile[INLINE_DIFF_LINES_KEY][index - 2]) || 0
      );
    },
    callLoadMoreLines(
      endpoint,
      params,
      lineNumbers,
      fileHash,
      isExpandDown = false,
      nextLineNumbers = {},
    ) {
      this.loadMoreLines({ endpoint, params, lineNumbers, fileHash, isExpandDown, nextLineNumbers })
        .then(() => {
          this.isRequesting = false;
        })
        .catch(() => {
          createFlash({
            message: s__('Diffs|Something went wrong while fetching diff lines.'),
          });
          this.isRequesting = false;
        });
    },
    handleExpandLines(type = EXPAND_ALL) {
      if (this.isRequesting) {
        return;
      }

      this.isRequesting = true;
      const endpoint = this.contextLinesPath;
      const { fileHash } = this;
      const view = INLINE_DIFF_VIEW_TYPE;
      const oldLineNumber = this.line.meta_data.old_pos || 0;
      const newLineNumber = this.line.meta_data.new_pos || 0;
      const offset = newLineNumber - oldLineNumber;

      const expandOptions = { endpoint, fileHash, view, oldLineNumber, newLineNumber, offset };

      if (type === EXPAND_UP) {
        this.handleExpandUpLines(expandOptions);
      } else if (type === EXPAND_DOWN) {
        this.handleExpandDownLines(expandOptions);
      } else {
        this.handleExpandAllLines(expandOptions);
      }
    },
    handleExpandUpLines(expandOptions) {
      const { endpoint, fileHash, view, oldLineNumber, newLineNumber, offset } = expandOptions;

      const bottom = this.isBottom;
      const lineNumber = newLineNumber - 1;
      const to = lineNumber;
      let since = lineNumber - UNFOLD_COUNT;
      let unfold = true;

      const prevLineNumber = this.getPrevLineNumber(oldLineNumber, newLineNumber);
      if (since <= prevLineNumber + 1) {
        since = prevLineNumber + 1;
        unfold = false;
      }

      const params = { since, to, bottom, offset, unfold, view };
      const lineNumbers = { oldLineNumber, newLineNumber };
      this.callLoadMoreLines(endpoint, params, lineNumbers, fileHash);
    },
    handleExpandDownLines(expandOptions) {
      const {
        endpoint,
        fileHash,
        view,
        oldLineNumber: metaOldPos,
        newLineNumber: metaNewPos,
        offset,
      } = expandOptions;

      const bottom = true;
      const nextLineNumbers = {
        old_line: metaOldPos,
        new_line: metaNewPos,
      };

      let unfold = true;
      let isExpandDown = false;
      let oldLineNumber = metaOldPos;
      let newLineNumber = metaNewPos;
      let lineNumber = metaNewPos + 1;
      let since = lineNumber;
      let to = lineNumber + UNFOLD_COUNT;

      if (!this.isBottom) {
        const prevLineNumber = this.getPrevLineNumber(oldLineNumber, newLineNumber);

        isExpandDown = true;
        oldLineNumber = prevLineNumber - offset;
        newLineNumber = prevLineNumber;
        lineNumber = prevLineNumber + 1;
        since = lineNumber;
        to = lineNumber + UNFOLD_COUNT;

        if (to >= metaNewPos) {
          to = metaNewPos - 1;
          unfold = false;
        }
      }

      const params = { since, to, bottom, offset, unfold, view };
      const lineNumbers = { oldLineNumber, newLineNumber };
      this.callLoadMoreLines(
        endpoint,
        params,
        lineNumbers,
        fileHash,
        isExpandDown,
        nextLineNumbers,
      );
    },
    handleExpandAllLines(expandOptions) {
      const { endpoint, fileHash, view, oldLineNumber, newLineNumber, offset } = expandOptions;
      const bottom = this.isBottom;
      const unfold = false;
      let since;
      let to;

      if (this.isTop) {
        since = 1;
        to = newLineNumber - 1;
      } else if (bottom) {
        since = newLineNumber + 1;
        to = -1;
      } else {
        const prevLineNumber = this.getPrevLineNumber(oldLineNumber, newLineNumber);
        since = prevLineNumber + 1;
        to = newLineNumber - 1;
      }

      const params = { since, to, bottom, offset, unfold, view };
      const lineNumbers = { oldLineNumber, newLineNumber };
      this.callLoadMoreLines(endpoint, params, lineNumbers, fileHash);
    },
  },
};
</script>

<template>
  <div class="content js-line-expansion-content">
    <a
      v-if="canExpandDown"
      class="gl-mx-2 gl-cursor-pointer js-unfold-down gl-display-inline-block gl-py-4"
      @click="handleExpandLines(EXPAND_DOWN)"
    >
      <gl-icon :size="12" name="expand-down" />
      <span>{{ $options.i18n.showMore }}</span>
    </a>
    <a class="gl-mx-2 cursor-pointer js-unfold-all" @click="handleExpandLines()">
      <gl-icon :size="12" name="expand" />
      <span>{{ $options.i18n.showAll }}</span>
    </a>
    <a
      v-if="canExpandUp"
      class="gl-mx-2 gl-cursor-pointer js-unfold gl-display-inline-block gl-py-4"
      @click="handleExpandLines(EXPAND_UP)"
    >
      <gl-icon :size="12" name="expand-up" />
      <span>{{ $options.i18n.showMore }}</span>
    </a>
  </div>
</template>
