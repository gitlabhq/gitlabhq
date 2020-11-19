<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import $ from 'jquery';
import { GlTooltipDirective, GlIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { CONTEXT_LINE_CLASS_NAME, PARALLEL_DIFF_VIEW_TYPE } from '../constants';
import DiffGutterAvatars from './diff_gutter_avatars.vue';
import * as utils from './diff_row_utils';

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
        const line = this.line.left?.line_code ? this.line.left : this.line.right;
        return utils.isHighlighted(state, line, this.isCommented);
      },
    }),
    classNameMap() {
      return {
        [CONTEXT_LINE_CLASS_NAME]: this.line.isContextLineLeft,
        [PARALLEL_DIFF_VIEW_TYPE]: true,
      };
    },
    parallelViewLeftLineType() {
      return utils.parallelViewLeftLineType(this.line, this.isHighlighted);
    },
    coverageState() {
      return this.fileLineCoverage(this.filePath, this.line.right.new_line);
    },
    classNameMapCellLeft() {
      return utils.classNameMapCell(
        this.line.left,
        this.isHighlighted,
        this.isLoggedIn,
        this.isLeftHover,
      );
    },
    classNameMapCellRight() {
      return utils.classNameMapCell(
        this.line.right,
        this.isHighlighted,
        this.isLoggedIn,
        this.isRightHover,
      );
    },
    addCommentTooltipLeft() {
      return utils.addCommentTooltip(this.line.left);
    },
    addCommentTooltipRight() {
      return utils.addCommentTooltip(this.line.right);
    },
    shouldRenderCommentButton() {
      return utils.shouldRenderCommentButton(this.isLoggedIn, this.isCommentButtonRendered);
    },
    shouldShowCommentButtonLeft() {
      return utils.shouldShowCommentButton(
        this.isLeftHover,
        this.line.isContextLineLeft,
        this.line.isMetaLineLeft,
        this.line.hasDiscussionsLeft,
      );
    },
    shouldShowCommentButtonRight() {
      return utils.shouldShowCommentButton(
        this.isRightHover,
        this.line.isContextLineRight,
        this.line.isMetaLineRight,
        this.line.hasDiscussionsRight,
      );
    },
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
    <template v-if="line.left && !line.isMatchLineLeft">
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
          :href="line.lineHrefOld"
          @click="setHighlightedRow(line.lineCode)"
        >
        </a>
        <diff-gutter-avatars
          v-if="line.hasDiscussionsLeft"
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
        :key="line.left.line_code"
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
    <template v-if="line.right && !line.isMatchLineRight">
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
          :href="line.lineHrefNew"
          @click="setHighlightedRow(line.lineCode)"
        >
        </a>
        <diff-gutter-avatars
          v-if="line.hasDiscussionsRight"
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
        :key="line.right.rich_text"
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
