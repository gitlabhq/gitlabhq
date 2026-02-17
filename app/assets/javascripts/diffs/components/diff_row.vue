<script>
/* eslint-disable vue/no-v-html */
/**
NOTE: This file uses v-html over v-safe-html for performance reasons, see:
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57842
* */
import {
  PARALLEL_DIFF_VIEW_TYPE,
  CONFLICT_MARKER_THEIR,
  CONFLICT_OUR,
  CONFLICT_THEIR,
  CONFLICT_MARKER,
} from '../constants';
import {
  getInteropInlineAttributes,
  getInteropOldSideAttributes,
  getInteropNewSideAttributes,
} from '../utils/interoperability';
import DiffGutterAvatars from './diff_gutter_avatars.vue';
import * as utils from './diff_row_utils';

export default {
  name: 'DiffRow',
  components: {
    DiffGutterAvatars,
    InlineFindingsGutterIconDropdown: () =>
      import('ee_component/diffs/components/inline_findings_gutter_icon_dropdown.vue'),
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
    coverageLoaded: {
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
    isHighlighted: {
      type: Boolean,
      required: true,
    },
    isFirstHighlightedLine: {
      type: Boolean,
      required: false,
      default: false,
    },
    isLastHighlightedLine: {
      type: Boolean,
      required: false,
      default: false,
    },
    fileLineCoverage: {
      type: Function,
      required: true,
    },
    userCanReply: {
      type: Boolean,
      required: true,
    },
  },
  emits: [
    'show-comment-form',
    'set-highlighted-row',
    'toggle-line-discussions',
    'toggle-code-quality-findings',
    'enterdragging',
    'startdragging',
    'stopdragging',
  ],
  computed: {
    classNameMap() {
      return {
        [PARALLEL_DIFF_VIEW_TYPE]: !this.inline,
        commented: this.isCommented,
      };
    },
    parallelViewLeftLineType() {
      return utils.parallelViewLeftLineType({
        line: this.line,
        highlighted: this.isHighlighted,
        commented: this.isCommented,
        selectionStart: this.isFirstHighlightedLine,
        selectionEnd: this.isLastHighlightedLine,
      });
    },
    coverageStateLeft() {
      if (!this.inline || !this.line.left) return {};
      return this.fileLineCoverage(this.filePath, this.line.left.new_line);
    },
    coverageStateRight() {
      if (!this.line.right) return {};
      return this.fileLineCoverage(this.filePath, this.line.right.new_line);
    },
    showCodequalityLeft() {
      return this.inline && this.line.left?.codequality?.length > 0;
    },
    showCodequalityRight() {
      return !this.inline && this.line.right?.codequality?.length > 0;
    },
    showSecurityLeft() {
      return this.inline && this.line.left?.sast?.length > 0;
    },
    showSecurityRight() {
      return !this.inline && this.line.right?.sast?.length > 0;
    },
    classNameMapCellLeft() {
      return utils.classNameMapCell({
        line: this.line?.left,
        highlighted: this.isHighlighted,
        commented: this.isCommented,
        selectionStart: this.isFirstHighlightedLine,
        selectionEnd: this.isLastHighlightedLine,
      });
    },
    classNameMapCellRight() {
      return utils.classNameMapCell({
        line: this.line?.right,
        highlighted: this.isHighlighted,
        commented: this.isCommented,
        selectionStart: this.isFirstHighlightedLine,
        selectionEnd: this.isLastHighlightedLine,
      });
    },
    interopLeftAttributes() {
      if (this.inline) {
        return getInteropInlineAttributes(this.line.left);
      }

      return getInteropOldSideAttributes(this.line.left);
    },
    interopRightAttributes() {
      return getInteropNewSideAttributes(this.line.right);
    },
  },
  methods: {
    shouldRenderCommentButton(side) {
      return (
        this.userCanReply && !this.line[`isContextLine${side}`] && !this.line[`isMetaLine${side}`]
      );
    },
    lineContent(line) {
      if (line.isConflictMarker) {
        return line.type === CONFLICT_MARKER_THEIR ? 'HEAD//our changes' : 'origin//their changes';
      }

      return line.rich_text;
    },
  },
  CONFLICT_MARKER,
  CONFLICT_MARKER_THEIR,
  CONFLICT_OUR,
  CONFLICT_THEIR,
};
</script>

<template>
  <div
    :class="[classNameMap, { expansion: line.left && line.left.type === 'expanded' }]"
    class="diff-grid-row diff-tr line_holder"
  >
    <div
      :id="line.left && line.left.line_code"
      data-testid="left-side"
      class="diff-grid-left left-side"
      v-bind="interopLeftAttributes"
      @dragover.prevent
      @dragenter="$emit('enterdragging', { ...line.left, index: index })"
      @dragend="$emit('stopdragging', $event)"
    >
      <template v-if="line.left && line.left.type !== $options.CONFLICT_MARKER">
        <div
          :class="classNameMapCellLeft"
          data-testid="left-line-number"
          class="diff-td diff-line-num"
        >
          <span
            v-if="
              !line.left.isConflictMarker &&
              shouldRenderCommentButton('Left') &&
              !line.hasDiscussionsLeft
            "
            class="add-diff-note tooltip-wrapper has-tooltip"
            :title="line.left.addCommentTooltip"
          >
            <div
              data-testid="left-comment-button"
              role="button"
              tabindex="0"
              :draggable="!line.left.commentsDisabled"
              type="button"
              class="add-diff-note unified-diff-components-diff-note-button note-button js-add-diff-note-button"
              :disabled="line.left.commentsDisabled"
              :aria-disabled="line.left.commentsDisabled"
              @click="
                !line.left.commentsDisabled && $emit('show-comment-form', line.left.line_code)
              "
              @keydown.enter="
                !line.left.commentsDisabled && $emit('show-comment-form', line.left.line_code)
              "
              @keydown.space="
                !line.left.commentsDisabled && $emit('show-comment-form', line.left.line_code)
              "
              @dragstart="
                !line.left.commentsDisabled &&
                  $emit('startdragging', {
                    event: $event,
                    line: { ...line.left, index: index },
                  })
              "
            ></div>
          </span>
          <a
            v-if="line.left.old_line && line.left.type !== $options.CONFLICT_THEIR"
            :data-linenumber="line.left.old_line"
            :href="line.lineHrefOld"
            :aria-label="line.left.old_line"
            @click="$emit('set-highlighted-row', { lineCode: line.lineCode, event: $event })"
          >
          </a>
          <diff-gutter-avatars
            v-if="line.hasDiscussionsLeft"
            :discussions="line.left.discussions"
            :discussions-expanded="line.left.discussionsExpanded"
            data-testid="left-discussions"
            @toggleLineDiscussions="
              $emit('toggle-line-discussions', {
                lineCode: line.left.line_code,
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
            :aria-label="line.left.new_line"
            @click="$emit('set-highlighted-row', { lineCode: line.lineCode, event: $event })"
          >
          </a>
        </div>
        <div
          :title="coverageStateLeft.text"
          :data-tooltip-custom-class="coverageStateLeft.class"
          :class="[parallelViewLeftLineType, coverageStateLeft.class]"
          class="diff-td line-coverage left-side has-tooltip"
        ></div>
        <div class="diff-td line-inline-findings left-side" :class="parallelViewLeftLineType">
          <inline-findings-gutter-icon-dropdown
            v-if="showCodequalityLeft || showSecurityLeft"
            :code-quality="line.left.codequality"
            :sast="line.left.sast"
            :file-path="filePath"
            @showInlineFindings="
              $emit(
                'toggle-code-quality-findings',
                line.left.codequality[0] ? line.left.codequality[0].line : line.left.sast[0].line,
              )
            "
          />
        </div>
        <div
          :key="line.left.line_code"
          :class="[
            parallelViewLeftLineType,
            { parallel: !inline, 'gl-font-bold': line.left.isConflictMarker },
          ]"
          class="diff-td line_content with-coverage left-side"
          data-testid="left-content"
          v-html="lineContent(line.left) /* v-html for performance, see top of file */"
        ></div>
      </template>
      <template v-else-if="!inline || (line.left && line.left.type === $options.CONFLICT_MARKER)">
        <div
          data-testid="left-empty-cell"
          class="diff-td diff-line-num old_line empty-cell"
          :class="classNameMapCellLeft"
        >
          &nbsp;
        </div>
        <div class="diff-td line-coverage left-side empty-cell" :class="classNameMapCellLeft"></div>
        <div
          class="diff-td line-inline-findings left-side empty-cell"
          :class="classNameMapCellLeft"
        ></div>
        <div
          class="diff-td line_content with-coverage left-side empty-cell"
          :class="[{ parallel: !inline }, ...classNameMapCellLeft]"
        ></div>
      </template>
    </div>
    <div
      v-if="!inline"
      :id="line.right && line.right.line_code"
      data-testid="right-side"
      class="diff-grid-right right-side"
      v-bind="interopRightAttributes"
      @dragover.prevent
      @dragenter="$emit('enterdragging', { ...line.right, index: index })"
      @dragend="$emit('stopdragging', $event)"
    >
      <template v-if="line.right">
        <div :class="classNameMapCellRight" class="diff-td diff-line-num new_line">
          <template v-if="line.right.type !== $options.CONFLICT_MARKER_THEIR">
            <span
              v-if="shouldRenderCommentButton('Right') && !line.hasDiscussionsRight"
              class="add-diff-note tooltip-wrapper has-tooltip"
              :title="line.right.addCommentTooltip"
            >
              <div
                data-testid="right-comment-button"
                role="button"
                tabindex="0"
                :draggable="!line.right.commentsDisabled"
                type="button"
                class="add-diff-note unified-diff-components-diff-note-button note-button js-add-diff-note-button"
                :disabled="line.right.commentsDisabled"
                :aria-disabled="line.right.commentsDisabled"
                @click="
                  !line.right.commentsDisabled && $emit('show-comment-form', line.right.line_code)
                "
                @keydown.enter="
                  !line.right.commentsDisabled && $emit('show-comment-form', line.right.line_code)
                "
                @keydown.space="
                  !line.right.commentsDisabled && $emit('show-comment-form', line.right.line_code)
                "
                @dragstart="
                  !line.right.commentsDisabled &&
                    $emit('startdragging', {
                      event: $event,
                      line: { ...line.right, index: index },
                    })
                "
              ></div>
            </span>
          </template>
          <a
            v-if="line.right.new_line"
            :data-linenumber="line.right.new_line"
            :href="line.lineHrefNew"
            :aria-label="line.right.new_line"
            @click="$emit('set-highlighted-row', { lineCode: line.lineCode, event: $event })"
          >
          </a>
          <diff-gutter-avatars
            v-if="line.hasDiscussionsRight"
            :discussions="line.right.discussions"
            :discussions-expanded="line.right.discussionsExpanded"
            data-testid="right-discussions"
            @toggleLineDiscussions="
              $emit('toggle-line-discussions', {
                lineCode: line.right.line_code,
                expanded: !line.right.discussionsExpanded,
              })
            "
          />
        </div>
        <div
          :title="coverageStateRight.text"
          :data-tooltip-custom-class="coverageStateRight.class"
          :class="[line.right.type, coverageStateRight.class, ...classNameMapCellRight]"
          class="diff-td line-coverage right-side has-tooltip"
        ></div>
        <div class="diff-td line-inline-findings right-side" :class="classNameMapCellRight">
          <inline-findings-gutter-icon-dropdown
            v-if="showCodequalityRight || showSecurityRight"
            :code-quality="line.right.codequality"
            :sast="line.right.sast"
            :file-path="filePath"
            data-testid="inlineFindingsIcon"
            @showInlineFindings="
              $emit(
                'toggle-code-quality-findings',
                line.right.codequality[0]
                  ? line.right.codequality[0].line
                  : line.right.sast[0].line,
              )
            "
          />
        </div>
        <div
          :key="line.right.rich_text"
          :class="[
            line.right.type,
            {
              'gl-font-bold': line.right.type === $options.CONFLICT_MARKER_THEIR,
            },
            ...classNameMapCellRight,
          ]"
          class="diff-td line_content with-coverage right-side parallel"
          v-html="lineContent(line.right) /* v-html for performance, see top of file */"
        ></div>
      </template>
      <template v-else>
        <div
          data-testid="right-empty-cell"
          class="diff-td diff-line-num old_line empty-cell"
          :class="classNameMapCellRight"
        ></div>
        <div
          class="diff-td line-coverage right-side empty-cell"
          :class="classNameMapCellRight"
        ></div>
        <div
          class="diff-td line-inline-findings right-side empty-cell"
          :class="classNameMapCellRight"
        ></div>
        <div
          class="diff-td line_content with-coverage right-side empty-cell parallel"
          :class="classNameMapCellRight"
        ></div>
      </template>
    </div>
  </div>
</template>
