<script>
import { mapState, mapActions } from 'vuex';
import createFlash from '~/flash';
import { s__ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';
import { UNFOLD_COUNT } from '../constants';
import * as utils from '../store/utils';
import tooltip from '../../vue_shared/directives/tooltip';

const EXPAND_ALL = 0;
const EXPAND_UP = 1;
const EXPAND_DOWN = 2;

export default {
  directives: {
    tooltip,
  },
  components: {
    Icon,
  },
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
    colspan: {
      type: Number,
      required: false,
      default: 3,
    },
  },
  computed: {
    ...mapState({
      diffViewType: state => state.diffs.diffViewType,
      diffFiles: state => state.diffs.diffFiles,
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
      const indexForInline = utils.findIndexInInlineLines(diffFile.highlighted_diff_lines, {
        oldLineNumber,
        newLineNumber,
      });
      const prevLine = diffFile.highlighted_diff_lines[indexForInline - 2];
      return (prevLine && prevLine.new_line) || 0;
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
          createFlash(s__('Diffs|Something went wrong while fetching diff lines.'));
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
      const view = this.diffViewType;
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
    handleExpandUpLines(expandOptions = EXPAND_ALL) {
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
  <td :colspan="colspan" class="text-center">
    <div class="content js-line-expansion-content">
      <a
        v-if="canExpandUp"
        v-tooltip
        class="cursor-pointer js-unfold unfold-icon d-inline-block pt-2 pb-2"
        data-placement="top"
        data-container="body"
        :title="__('Expand up')"
        @click="handleExpandLines(EXPAND_UP)"
      >
        <icon :size="12" name="expand-up" aria-hidden="true" />
      </a>
      <a class="mx-2 cursor-pointer js-unfold-all" @click="handleExpandLines()">
        <span>{{ s__('Diffs|Show all lines') }}</span>
      </a>
      <a
        v-if="canExpandDown"
        v-tooltip
        class="cursor-pointer js-unfold-down has-tooltip unfold-icon d-inline-block pt-2 pb-2"
        data-placement="top"
        data-container="body"
        :title="__('Expand down')"
        @click="handleExpandLines(EXPAND_DOWN)"
      >
        <icon :size="12" name="expand-down" aria-hidden="true" />
      </a>
    </div>
  </td>
</template>
