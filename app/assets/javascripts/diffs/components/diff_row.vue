<script>
import { mapActions, mapGetters, mapState } from 'vuex';
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
    isCommented: {
      type: Boolean,
      required: false,
      default: false,
    },
    inline: {
      type: Boolean,
      required: false,
      default: false,
    },
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
      return utils.classNameMapCell(this.line.left, this.isHighlighted, this.isLoggedIn);
    },
    classNameMapCellRight() {
      return utils.classNameMapCell(this.line.right, this.isHighlighted, this.isLoggedIn);
    },
    addCommentTooltipLeft() {
      return utils.addCommentTooltip(this.line.left);
    },
    addCommentTooltipRight() {
      return utils.addCommentTooltip(this.line.right);
    },
    shouldRenderCommentButton() {
      return (
        this.isLoggedIn &&
        !this.line.isContextLineLeft &&
        !this.line.isMetaLineLeft &&
        !this.line.hasDiscussionsLeft &&
        !this.line.hasDiscussionsRight
      );
    },
  },
  mounted() {
    this.scrollToLineIfNeededParallel(this.line);
  },
  methods: {
    ...mapActions('diffs', [
      'scrollToLineIfNeededParallel',
      'showCommentForm',
      'setHighlightedRow',
      'toggleLineDiscussions',
    ]),
    // Prevent text selecting on both sides of parallel diff view
    // Backport of the same code from legacy diff notes.
    handleParallelLineMouseDown(e) {
      const line = e.currentTarget;
      const table = line.closest('.diff-table');

      table.classList.remove('left-side-selected', 'right-side-selected');
      const [lineClass] = ['left-side', 'right-side'].filter(name => line.classList.contains(name));

      if (lineClass) {
        table.classList.add(`${lineClass}-selected`);
      }
    },
    handleCommentButton(line) {
      this.showCommentForm({ lineCode: line.line_code, fileHash: this.fileHash });
    },
  },
};
</script>

<template>
  <div :class="classNameMap" class="diff-grid-row diff-tr line_holder">
    <div class="diff-grid-left left-side">
      <template v-if="line.left">
        <div
          :class="classNameMapCellLeft"
          data-testid="leftLineNumber"
          class="diff-td diff-line-num old_line"
        >
          <span
            v-if="shouldRenderCommentButton"
            v-gl-tooltip
            data-testid="leftCommentButton"
            class="add-diff-note tooltip-wrapper"
            :title="addCommentTooltipLeft"
          >
            <button
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
            :data-linenumber="line.left.old_line"
            :href="line.lineHrefOld"
            @click="setHighlightedRow(line.lineCode)"
          >
          </a>
          <diff-gutter-avatars
            v-if="line.hasDiscussionsLeft"
            :discussions="line.left.discussions"
            :discussions-expanded="line.left.discussionsExpanded"
            data-testid="leftDiscussions"
            @toggleLineDiscussions="
              toggleLineDiscussions({
                lineCode: line.left.line_code,
                fileHash,
                expanded: !line.left.discussionsExpanded,
              })
            "
          />
        </div>
        <div v-if="inline" :class="classNameMapCellLeft" class="diff-td diff-line-num old_line">
          <a
            v-if="line.left.new_line"
            :data-linenumber="line.left.new_line"
            :href="line.lineHrefOld"
            @click="setHighlightedRow(line.lineCode)"
          >
          </a>
        </div>
        <div :class="parallelViewLeftLineType" class="diff-td line-coverage left-side"></div>
        <div
          :id="line.left.line_code"
          :key="line.left.line_code"
          v-safe-html="line.left.rich_text"
          :class="parallelViewLeftLineType"
          class="diff-td line_content with-coverage parallel left-side"
          data-testid="leftContent"
          @mousedown="handleParallelLineMouseDown"
        ></div>
      </template>
      <template v-else>
        <div data-testid="leftEmptyCell" class="diff-td diff-line-num old_line empty-cell"></div>
        <div v-if="inline" class="diff-td diff-line-num old_line empty-cell"></div>
        <div class="diff-td line-coverage left-side empty-cell"></div>
        <div class="diff-td line_content with-coverage parallel left-side empty-cell"></div>
      </template>
    </div>
    <div v-if="!inline" class="diff-grid-right right-side">
      <template v-if="line.right">
        <div :class="classNameMapCellRight" class="diff-td diff-line-num new_line">
          <span
            v-if="shouldRenderCommentButton"
            v-gl-tooltip
            data-testid="rightCommentButton"
            class="add-diff-note tooltip-wrapper"
            :title="addCommentTooltipRight"
          >
            <button
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
            :data-linenumber="line.right.new_line"
            :href="line.lineHrefNew"
            @click="setHighlightedRow(line.lineCode)"
          >
          </a>
          <diff-gutter-avatars
            v-if="line.hasDiscussionsRight"
            :discussions="line.right.discussions"
            :discussions-expanded="line.right.discussionsExpanded"
            data-testid="rightDiscussions"
            @toggleLineDiscussions="
              toggleLineDiscussions({
                lineCode: line.right.line_code,
                fileHash,
                expanded: !line.right.discussionsExpanded,
              })
            "
          />
        </div>
        <div
          v-gl-tooltip.hover
          :title="coverageState.text"
          :class="[line.right.type, coverageState.class, { hll: isHighlighted }]"
          class="diff-td line-coverage right-side"
        ></div>
        <div
          :id="line.right.line_code"
          :key="line.right.rich_text"
          v-safe-html="line.right.rich_text"
          :class="[
            line.right.type,
            {
              hll: isHighlighted,
            },
          ]"
          class="diff-td line_content with-coverage parallel right-side"
          @mousedown="handleParallelLineMouseDown"
        ></div>
      </template>
      <template v-else>
        <div data-testid="rightEmptyCell" class="diff-td diff-line-num old_line empty-cell"></div>
        <div class="diff-td diff-line-num old_line empty-cell"></div>
        <div class="diff-td line-coverage right-side empty-cell"></div>
        <div class="diff-td line_content with-coverage parallel right-side empty-cell"></div>
      </template>
    </div>
  </div>
</template>
