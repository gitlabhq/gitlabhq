<script>
/* eslint-disable vue/no-v-html */
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import {
  MATCH_LINE_TYPE,
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  CONTEXT_LINE_CLASS_NAME,
  LINE_POSITION_LEFT,
  LINE_POSITION_RIGHT,
  LINE_HOVER_CLASS_NAME,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  EMPTY_CELL_TYPE,
} from '../constants';
import { __ } from '~/locale';
import { getParameterByName, parseBoolean } from '~/lib/utils/common_utils';
import DiffGutterAvatars from './diff_gutter_avatars.vue';

export default {
  components: {
    DiffGutterAvatars,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    fileHash: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    isBottom: {
      type: Boolean,
      required: false,
      default: false,
    },
    isCommented: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isHover: false,
    };
  },
  computed: {
    ...mapGetters(['isLoggedIn']),
    ...mapGetters('diffs', ['fileLineCoverage']),
    ...mapState({
      isHighlighted(state) {
        if (this.isCommented) return true;

        const lineCode = this.line.line_code;
        return lineCode ? lineCode === state.diffs.highlightedRow : false;
      },
    }),
    isContextLine() {
      return this.line.type === CONTEXT_LINE_TYPE;
    },
    classNameMap() {
      return [
        this.line.type,
        {
          [CONTEXT_LINE_CLASS_NAME]: this.isContextLine,
        },
      ];
    },
    inlineRowId() {
      return this.line.line_code || `${this.fileHash}_${this.line.old_line}_${this.line.new_line}`;
    },
    isMatchLine() {
      return this.line.type === MATCH_LINE_TYPE;
    },
    coverageState() {
      return this.fileLineCoverage(this.filePath, this.line.new_line);
    },
    isMetaLine() {
      const { type } = this.line;

      return (
        type === OLD_NO_NEW_LINE_TYPE || type === NEW_NO_NEW_LINE_TYPE || type === EMPTY_CELL_TYPE
      );
    },
    classNameMapCell() {
      const { type } = this.line;

      return [
        type,
        {
          hll: this.isHighlighted,
          [LINE_HOVER_CLASS_NAME]:
            this.isLoggedIn && this.isHover && !this.isContextLine && !this.isMetaLine,
        },
      ];
    },
    addCommentTooltip() {
      const brokenSymlinks = this.line.commentsDisabled;
      let tooltip = __('Add a comment to this line');

      if (brokenSymlinks) {
        if (brokenSymlinks.wasSymbolic || brokenSymlinks.isSymbolic) {
          tooltip = __(
            'Commenting on symbolic links that replace or are replaced by files is currently not supported.',
          );
        } else if (brokenSymlinks.wasReal || brokenSymlinks.isReal) {
          tooltip = __(
            'Commenting on files that replace or are replaced by symbolic links is currently not supported.',
          );
        }
      }

      return tooltip;
    },
    shouldRenderCommentButton() {
      if (this.isLoggedIn) {
        const isDiffHead = parseBoolean(getParameterByName('diff_head'));
        return !isDiffHead || gon.features?.mergeRefHeadComments;
      }

      return false;
    },
    shouldShowCommentButton() {
      return this.isHover && !this.isContextLine && !this.isMetaLine && !this.hasDiscussions;
    },
    hasDiscussions() {
      return this.line.discussions && this.line.discussions.length > 0;
    },
    lineHref() {
      return `#${this.line.line_code || ''}`;
    },
    lineCode() {
      return (
        this.line.line_code ||
        (this.line.left && this.line.left.line_code) ||
        (this.line.right && this.line.right.line_code)
      );
    },
    shouldShowAvatarsOnGutter() {
      return this.hasDiscussions;
    },
  },
  created() {
    this.newLineType = NEW_LINE_TYPE;
    this.oldLineType = OLD_LINE_TYPE;
    this.linePositionLeft = LINE_POSITION_LEFT;
    this.linePositionRight = LINE_POSITION_RIGHT;
  },
  mounted() {
    this.scrollToLineIfNeededInline(this.line);
  },
  methods: {
    ...mapActions('diffs', [
      'scrollToLineIfNeededInline',
      'showCommentForm',
      'setHighlightedRow',
      'toggleLineDiscussions',
    ]),
    handleMouseMove(e) {
      // To show the comment icon on the gutter we need to know if we hover the line.
      // Current table structure doesn't allow us to do this with CSS in both of the diff view types
      this.isHover = e.type === 'mouseover';
    },
    handleCommentButton() {
      this.showCommentForm({ lineCode: this.line.line_code, fileHash: this.fileHash });
    },
  },
};
</script>

<template>
  <tr
    v-if="!isMatchLine"
    :id="inlineRowId"
    :class="classNameMap"
    class="line_holder"
    @mouseover="handleMouseMove"
    @mouseout="handleMouseMove"
  >
    <td ref="oldTd" class="diff-line-num old_line" :class="classNameMapCell">
      <span
        v-if="shouldRenderCommentButton"
        ref="addNoteTooltip"
        v-gl-tooltip
        class="add-diff-note tooltip-wrapper"
        :title="addCommentTooltip"
      >
        <button
          v-show="shouldShowCommentButton"
          ref="addDiffNoteButton"
          type="button"
          class="add-diff-note note-button js-add-diff-note-button qa-diff-comment"
          :disabled="line.commentsDisabled"
          @click="handleCommentButton"
        >
          <gl-icon :size="12" name="comment" />
        </button>
      </span>
      <a
        v-if="line.old_line"
        ref="lineNumberRefOld"
        :data-linenumber="line.old_line"
        :href="lineHref"
        @click="setHighlightedRow(lineCode)"
      >
      </a>
      <diff-gutter-avatars
        v-if="shouldShowAvatarsOnGutter"
        :discussions="line.discussions"
        :discussions-expanded="line.discussionsExpanded"
        @toggleLineDiscussions="
          toggleLineDiscussions({ lineCode, fileHash, expanded: !line.discussionsExpanded })
        "
      />
    </td>
    <td ref="newTd" class="diff-line-num new_line qa-new-diff-line" :class="classNameMapCell">
      <a
        v-if="line.new_line"
        ref="lineNumberRefNew"
        :data-linenumber="line.new_line"
        :href="lineHref"
        @click="setHighlightedRow(lineCode)"
      >
      </a>
    </td>
    <td
      v-gl-tooltip.hover
      :title="coverageState.text"
      :class="[line.type, coverageState.class, { hll: isHighlighted }]"
      class="line-coverage"
    ></td>
    <td
      :class="[
        line.type,
        {
          hll: isHighlighted,
        },
      ]"
      class="line_content with-coverage"
      v-html="line.rich_text"
    ></td>
  </tr>
</template>
