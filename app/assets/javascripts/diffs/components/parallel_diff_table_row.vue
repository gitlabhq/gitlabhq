<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import $ from 'jquery';
import { GlTooltipDirective, GlIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import {
  MATCH_LINE_TYPE,
  NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  CONTEXT_LINE_CLASS_NAME,
  OLD_NO_NEW_LINE_TYPE,
  PARALLEL_DIFF_VIEW_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  EMPTY_CELL_TYPE,
  LINE_HOVER_CLASS_NAME,
} from '../constants';
import { __ } from '~/locale';
import { getParameterByName, parseBoolean } from '~/lib/utils/common_utils';
import DiffGutterAvatars from './diff_gutter_avatars.vue';

export default {
  components: {
    GlIcon,
    DiffGutterAvatars,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
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
      isLeftHover: false,
      isRightHover: false,
      isCommentButtonRendered: false,
    };
  },
  computed: {
    ...mapGetters('diffs', ['fileLineCoverage']),
    ...mapGetters(['isLoggedIn']),
    ...mapState({
      isHighlighted(state) {
        if (this.isCommented) return true;

        const lineCode =
          (this.line.left && this.line.left.line_code) ||
          (this.line.right && this.line.right.line_code);

        return lineCode ? lineCode === state.diffs.highlightedRow : false;
      },
    }),
    isContextLineLeft() {
      return this.line.left && this.line.left.type === CONTEXT_LINE_TYPE;
    },
    isContextLineRight() {
      return this.line.right && this.line.right.type === CONTEXT_LINE_TYPE;
    },
    classNameMap() {
      return {
        [CONTEXT_LINE_CLASS_NAME]: this.isContextLineLeft,
        [PARALLEL_DIFF_VIEW_TYPE]: true,
      };
    },
    parallelViewLeftLineType() {
      if (this.line.right && this.line.right.type === NEW_NO_NEW_LINE_TYPE) {
        return OLD_NO_NEW_LINE_TYPE;
      }

      const lineTypeClass = this.line.left ? this.line.left.type : EMPTY_CELL_TYPE;

      return [
        lineTypeClass,
        {
          hll: this.isHighlighted,
        },
      ];
    },
    isMatchLineLeft() {
      return this.line.left && this.line.left.type === MATCH_LINE_TYPE;
    },
    isMatchLineRight() {
      return this.line.right && this.line.right.type === MATCH_LINE_TYPE;
    },
    coverageState() {
      return this.fileLineCoverage(this.filePath, this.line.right.new_line);
    },
    classNameMapCellLeft() {
      const { type } = this.line.left;

      return [
        type,
        {
          hll: this.isHighlighted,
          [LINE_HOVER_CLASS_NAME]:
            this.isLoggedIn && this.isLeftHover && !this.isContextLineLeft && !this.isMetaLineLeft,
        },
      ];
    },
    classNameMapCellRight() {
      const { type } = this.line.right;

      return [
        type,
        {
          hll: this.isHighlighted,
          [LINE_HOVER_CLASS_NAME]:
            this.isLoggedIn &&
            this.isRightHover &&
            !this.isContextLineRight &&
            !this.isMetaLineRight,
        },
      ];
    },
    addCommentTooltipLeft() {
      const brokenSymlinks = this.line.left.commentsDisabled;
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
    addCommentTooltipRight() {
      const brokenSymlinks = this.line.right.commentsDisabled;
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
      if (!this.isCommentButtonRendered) {
        return false;
      }

      if (this.isLoggedIn) {
        const isDiffHead = parseBoolean(getParameterByName('diff_head'));
        return !isDiffHead || gon.features?.mergeRefHeadComments;
      }

      return false;
    },
    shouldShowCommentButtonLeft() {
      return (
        this.isLeftHover &&
        !this.isContextLineLeft &&
        !this.isMetaLineLeft &&
        !this.hasDiscussionsLeft
      );
    },
    shouldShowCommentButtonRight() {
      return (
        this.isRightHover &&
        !this.isContextLineRight &&
        !this.isMetaLineRight &&
        !this.hasDiscussionsRight
      );
    },
    hasDiscussionsLeft() {
      return this.line.left?.discussions?.length > 0;
    },
    hasDiscussionsRight() {
      return this.line.right?.discussions?.length > 0;
    },
    lineHrefOld() {
      return `#${this.line.left.line_code || ''}`;
    },
    lineHrefNew() {
      return `#${this.line.right.line_code || ''}`;
    },
    lineCode() {
      return (
        (this.line.left && this.line.left.line_code) ||
        (this.line.right && this.line.right.line_code)
      );
    },
    isMetaLineLeft() {
      const type = this.line.left?.type;

      return (
        type === OLD_NO_NEW_LINE_TYPE || type === NEW_NO_NEW_LINE_TYPE || type === EMPTY_CELL_TYPE
      );
    },
    isMetaLineRight() {
      const type = this.line.right?.type;

      return (
        type === OLD_NO_NEW_LINE_TYPE || type === NEW_NO_NEW_LINE_TYPE || type === EMPTY_CELL_TYPE
      );
    },
  },
  created() {
    this.newLineType = NEW_LINE_TYPE;
    this.oldLineType = OLD_LINE_TYPE;
    this.parallelDiffViewType = PARALLEL_DIFF_VIEW_TYPE;
  },
  mounted() {
    this.scrollToLineIfNeededParallel(this.line);
    this.unwatchShouldShowCommentButton = this.$watch(
      vm => [vm.shouldShowCommentButtonLeft, vm.shouldShowCommentButtonRight].join(),
      newVal => {
        if (newVal) {
          this.isCommentButtonRendered = true;
          this.unwatchShouldShowCommentButton();
        }
      },
    );
  },
  beforeDestroy() {
    this.unwatchShouldShowCommentButton();
  },
  methods: {
    ...mapActions('diffs', [
      'scrollToLineIfNeededParallel',
      'showCommentForm',
      'setHighlightedRow',
      'toggleLineDiscussions',
    ]),
    handleMouseMove(e) {
      const isHover = e.type === 'mouseover';
      const hoveringCell = e.target.closest('td');
      const allCellsInHoveringRow = Array.from(e.currentTarget.children);
      const hoverIndex = allCellsInHoveringRow.indexOf(hoveringCell);

      if (hoverIndex >= 3) {
        this.isRightHover = isHover;
      } else {
        this.isLeftHover = isHover;
      }
    },
    // Prevent text selecting on both sides of parallel diff view
    // Backport of the same code from legacy diff notes.
    handleParallelLineMouseDown(e) {
      const line = $(e.currentTarget);
      const table = line.closest('table');

      table.removeClass('left-side-selected right-side-selected');
      const [lineClass] = ['left-side', 'right-side'].filter(name => line.hasClass(name));

      if (lineClass) {
        table.addClass(`${lineClass}-selected`);
      }
    },
    handleCommentButton(line) {
      this.showCommentForm({ lineCode: line.line_code, fileHash: this.fileHash });
    },
  },
};
</script>

<template>
  <tr
    :class="classNameMap"
    class="line_holder"
    @mouseover="handleMouseMove"
    @mouseout="handleMouseMove"
  >
    <template v-if="line.left && !isMatchLineLeft">
      <td ref="oldTd" :class="classNameMapCellLeft" class="diff-line-num old_line">
        <span
          v-if="shouldRenderCommentButton"
          ref="addNoteTooltipLeft"
          v-gl-tooltip
          class="add-diff-note tooltip-wrapper"
          :title="addCommentTooltipLeft"
        >
          <button
            v-show="shouldShowCommentButtonLeft"
            ref="addDiffNoteButtonLeft"
            type="button"
            class="add-diff-note note-button js-add-diff-note-button qa-diff-comment"
            :disabled="line.left.commentsDisabled"
            @click="handleCommentButton(line.left)"
          >
            <gl-icon :size="12" name="comment" />
          </button>
        </span>
        <a
          v-if="line.left.old_line"
          ref="lineNumberRefOld"
          :data-linenumber="line.left.old_line"
          :href="lineHrefOld"
          @click="setHighlightedRow(lineCode)"
        >
        </a>
        <diff-gutter-avatars
          v-if="hasDiscussionsLeft"
          :discussions="line.left.discussions"
          :discussions-expanded="line.left.discussionsExpanded"
          @toggleLineDiscussions="
            toggleLineDiscussions({
              lineCode: line.left.line_code,
              fileHash,
              expanded: !line.left.discussionsExpanded,
            })
          "
        />
      </td>
      <td :class="parallelViewLeftLineType" class="line-coverage left-side"></td>
      <td
        :id="line.left.line_code"
        v-safe-html="line.left.rich_text"
        :class="parallelViewLeftLineType"
        class="line_content with-coverage parallel left-side"
        @mousedown="handleParallelLineMouseDown"
      ></td>
    </template>
    <template v-else>
      <td class="diff-line-num old_line empty-cell"></td>
      <td class="line-coverage left-side empty-cell"></td>
      <td class="line_content with-coverage parallel left-side empty-cell"></td>
    </template>
    <template v-if="line.right && !isMatchLineRight">
      <td ref="newTd" :class="classNameMapCellRight" class="diff-line-num new_line">
        <span
          v-if="shouldRenderCommentButton"
          ref="addNoteTooltipRight"
          v-gl-tooltip
          class="add-diff-note tooltip-wrapper"
          :title="addCommentTooltipRight"
        >
          <button
            v-show="shouldShowCommentButtonRight"
            ref="addDiffNoteButtonRight"
            type="button"
            class="add-diff-note note-button js-add-diff-note-button qa-diff-comment"
            :disabled="line.right.commentsDisabled"
            @click="handleCommentButton(line.right)"
          >
            <gl-icon :size="12" name="comment" />
          </button>
        </span>
        <a
          v-if="line.right.new_line"
          ref="lineNumberRefNew"
          :data-linenumber="line.right.new_line"
          :href="lineHrefNew"
          @click="setHighlightedRow(lineCode)"
        >
        </a>
        <diff-gutter-avatars
          v-if="hasDiscussionsRight"
          :discussions="line.right.discussions"
          :discussions-expanded="line.right.discussionsExpanded"
          @toggleLineDiscussions="
            toggleLineDiscussions({
              lineCode: line.right.line_code,
              fileHash,
              expanded: !line.right.discussionsExpanded,
            })
          "
        />
      </td>
      <td
        v-gl-tooltip.hover
        :title="coverageState.text"
        :class="[line.right.type, coverageState.class, { hll: isHighlighted }]"
        class="line-coverage right-side"
      ></td>
      <td
        :id="line.right.line_code"
        v-safe-html="line.right.rich_text"
        :class="[
          line.right.type,
          {
            hll: isHighlighted,
          },
        ]"
        class="line_content with-coverage parallel right-side"
        @mousedown="handleParallelLineMouseDown"
      ></td>
    </template>
    <template v-else>
      <td class="diff-line-num old_line empty-cell"></td>
      <td class="line-coverage right-side empty-cell"></td>
      <td class="line_content with-coverage parallel right-side empty-cell"></td>
    </template>
  </tr>
</template>
