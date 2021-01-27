<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlTooltipDirective, GlIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import {
  CONTEXT_LINE_CLASS_NAME,
  PARALLEL_DIFF_VIEW_TYPE,
  CONFLICT_MARKER_OUR,
  CONFLICT_MARKER_THEIR,
  CONFLICT_OUR,
  CONFLICT_THEIR,
  CONFLICT_MARKER,
} from '../constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
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
  mixins: [glFeatureFlagsMixin()],
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
    index: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      dragging: false,
    };
  },
  computed: {
    ...mapGetters('diffs', ['fileLineCoverage']),
    ...mapGetters(['isLoggedIn']),
    ...mapState({
      isHighlighted(state) {
        const line = this.line.left?.line_code ? this.line.left : this.line.right;
        return utils.isHighlighted(state, line, false);
      },
    }),
    classNameMap() {
      return {
        [CONTEXT_LINE_CLASS_NAME]: this.line.isContextLineLeft,
        [PARALLEL_DIFF_VIEW_TYPE]: !this.inline,
        commented: this.isCommented,
      };
    },
    parallelViewLeftLineType() {
      return utils.parallelViewLeftLineType(this.line, this.isHighlighted || this.isCommented);
    },
    coverageStateLeft() {
      if (!this.inline || !this.line.left) return {};
      return this.fileLineCoverage(this.filePath, this.line.left.new_line);
    },
    coverageStateRight() {
      if (!this.line.right) return {};
      return this.fileLineCoverage(this.filePath, this.line.right.new_line);
    },
    classNameMapCellLeft() {
      return utils.classNameMapCell({
        line: this.line.left,
        hll: this.isHighlighted || this.isCommented,
        isLoggedIn: this.isLoggedIn,
      });
    },
    classNameMapCellRight() {
      return utils.classNameMapCell({
        line: this.line.right,
        hll: this.isHighlighted || this.isCommented,
        isLoggedIn: this.isLoggedIn,
      });
    },
    addCommentTooltipLeft() {
      return utils.addCommentTooltip(this.line.left, this.glFeatures.dragCommentSelection);
    },
    addCommentTooltipRight() {
      return utils.addCommentTooltip(this.line.right, this.glFeatures.dragCommentSelection);
    },
    emptyCellRightClassMap() {
      return { conflict_their: this.line.left?.type === CONFLICT_OUR };
    },
    emptyCellLeftClassMap() {
      return { conflict_our: this.line.right?.type === CONFLICT_THEIR };
    },
    shouldRenderCommentButton() {
      return this.isLoggedIn && !this.line.isContextLineLeft && !this.line.isMetaLineLeft;
    },
    isLeftConflictMarker() {
      return [CONFLICT_MARKER_OUR, CONFLICT_MARKER_THEIR].includes(this.line.left?.type);
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
      const [lineClass] = ['left-side', 'right-side'].filter((name) =>
        line.classList.contains(name),
      );

      if (lineClass) {
        table.classList.add(`${lineClass}-selected`);
      }
    },
    handleCommentButton(line) {
      this.showCommentForm({ lineCode: line.line_code, fileHash: this.fileHash });
    },
    conflictText(line) {
      return line.type === CONFLICT_MARKER_THEIR
        ? this.$options.THEIR_CHANGES
        : this.$options.OUR_CHANGES;
    },
    onDragEnd() {
      this.dragging = false;
      if (!this.glFeatures.dragCommentSelection) return;

      this.$emit('stopdragging');
    },
    onDragEnter(line, index) {
      if (!this.glFeatures.dragCommentSelection) return;

      this.$emit('enterdragging', { ...line, index });
    },
    onDragStart(line) {
      this.$root.$emit('bv::hide::tooltip');
      this.dragging = true;
      this.$emit('startdragging', line);
    },
  },
  OUR_CHANGES: 'HEAD//our changes',
  THEIR_CHANGES: 'origin//their changes',
  CONFLICT_MARKER,
  CONFLICT_MARKER_THEIR,
  CONFLICT_OUR,
  CONFLICT_THEIR,
};
</script>

<template>
  <div :class="classNameMap" class="diff-grid-row diff-tr line_holder">
    <div
      data-testid="left-side"
      class="diff-grid-left left-side"
      @dragover.prevent
      @dragenter="onDragEnter(line.left, index)"
      @dragend="onDragEnd"
    >
      <template v-if="line.left && line.left.type !== $options.CONFLICT_MARKER">
        <div
          :class="classNameMapCellLeft"
          data-testid="leftLineNumber"
          class="diff-td diff-line-num"
        >
          <template v-if="!isLeftConflictMarker">
            <span
              v-if="shouldRenderCommentButton && !line.hasDiscussionsLeft"
              v-gl-tooltip
              data-testid="leftCommentButton"
              class="add-diff-note tooltip-wrapper"
              :title="addCommentTooltipLeft"
            >
              <button
                :draggable="glFeatures.dragCommentSelection"
                type="button"
                class="add-diff-note note-button js-add-diff-note-button qa-diff-comment"
                :class="{ 'gl-cursor-grab': dragging }"
                :disabled="line.left.commentsDisabled"
                @click="handleCommentButton(line.left)"
                @dragstart="onDragStart({ ...line.left, index })"
              >
                <gl-icon :size="12" name="comment" />
              </button>
            </span>
          </template>
          <a
            v-if="line.left.old_line && line.left.type !== $options.CONFLICT_THEIR"
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
        <div v-if="inline" :class="classNameMapCellLeft" class="diff-td diff-line-num">
          <a
            v-if="line.left.new_line && line.left.type !== $options.CONFLICT_OUR"
            :data-linenumber="line.left.new_line"
            :href="line.lineHrefOld"
            @click="setHighlightedRow(line.lineCode)"
          >
          </a>
        </div>
        <div
          v-gl-tooltip.hover
          :title="coverageStateLeft.text"
          :class="[...parallelViewLeftLineType, coverageStateLeft.class]"
          class="diff-td line-coverage left-side"
        ></div>
        <div
          :id="line.left.line_code"
          :key="line.left.line_code"
          :class="[parallelViewLeftLineType, { parallel: !inline }]"
          class="diff-td line_content with-coverage left-side"
          data-testid="leftContent"
          @mousedown="handleParallelLineMouseDown"
        >
          <strong v-if="isLeftConflictMarker">{{ conflictText(line.left) }}</strong>
          <span v-else v-safe-html="line.left.rich_text"></span>
        </div>
      </template>
      <template v-else-if="!inline || (line.left && line.left.type === $options.CONFLICT_MARKER)">
        <div
          data-testid="leftEmptyCell"
          class="diff-td diff-line-num old_line empty-cell"
          :class="emptyCellLeftClassMap"
        >
          &nbsp;
        </div>
        <div
          v-if="inline"
          class="diff-td diff-line-num old_line empty-cell"
          :class="emptyCellLeftClassMap"
        ></div>
        <div
          class="diff-td line-coverage left-side empty-cell"
          :class="emptyCellLeftClassMap"
        ></div>
        <div
          class="diff-td line_content with-coverage left-side empty-cell"
          :class="[emptyCellLeftClassMap, { parallel: !inline }]"
        ></div>
      </template>
    </div>
    <div
      v-if="!inline"
      data-testid="right-side"
      class="diff-grid-right right-side"
      @dragover.prevent
      @dragenter="onDragEnter(line.right, index)"
      @dragend="onDragEnd"
    >
      <template v-if="line.right">
        <div :class="classNameMapCellRight" class="diff-td diff-line-num new_line">
          <template v-if="line.right.type !== $options.CONFLICT_MARKER_THEIR">
            <span
              v-if="shouldRenderCommentButton && !line.hasDiscussionsRight"
              v-gl-tooltip
              data-testid="rightCommentButton"
              class="add-diff-note tooltip-wrapper"
              :title="addCommentTooltipRight"
            >
              <button
                :draggable="glFeatures.dragCommentSelection"
                type="button"
                class="add-diff-note note-button js-add-diff-note-button qa-diff-comment"
                :class="{ 'gl-cursor-grab': dragging }"
                :disabled="line.right.commentsDisabled"
                @click="handleCommentButton(line.right)"
                @dragstart="onDragStart({ ...line.right, index })"
              >
                <gl-icon :size="12" name="comment" />
              </button>
            </span>
          </template>
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
          :title="coverageStateRight.text"
          :class="[
            line.right.type,
            coverageStateRight.class,
            { hll: isHighlighted, hll: isCommented },
          ]"
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
              hll: isCommented,
              parallel: !inline,
            },
          ]"
          class="diff-td line_content with-coverage right-side"
          @mousedown="handleParallelLineMouseDown"
        >
          <strong v-if="line.right.type === $options.CONFLICT_MARKER_THEIR">{{
            conflictText(line.right)
          }}</strong>
          <span v-else v-safe-html="line.right.rich_text"></span>
        </div>
      </template>
      <template v-else>
        <div
          data-testid="rightEmptyCell"
          class="diff-td diff-line-num old_line empty-cell"
          :class="emptyCellRightClassMap"
        ></div>
        <div
          v-if="inline"
          class="diff-td diff-line-num old_line empty-cell"
          :class="emptyCellRightClassMap"
        ></div>
        <div
          class="diff-td line-coverage right-side empty-cell"
          :class="emptyCellRightClassMap"
        ></div>
        <div
          class="diff-td line_content with-coverage right-side empty-cell"
          :class="[emptyCellRightClassMap, { parallel: !inline }]"
        ></div>
      </template>
    </div>
  </div>
</template>
