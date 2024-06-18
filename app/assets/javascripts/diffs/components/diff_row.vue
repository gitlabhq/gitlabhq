<script>
/* eslint-disable vue/no-v-html */
/**
NOTE: This file uses v-html over v-safe-html for performance reasons, see:
https://gitlab.com/gitlab-org/gitlab/-/merge_requests/57842
* */
import { memoize } from 'lodash';
import { isLoggedIn } from '~/lib/utils/common_utils';
import { compatFunctionalMixin } from '~/lib/utils/vue3compat/compat_functional_mixin';
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
  DiffGutterAvatars,
  InlineFindingsGutterIconDropdown: () =>
    import('ee_component/diffs/components/inline_findings_gutter_icon_dropdown.vue'),

  // Temporary mixin for migration from Vue.js 2 to @vue/compat
  mixins: [compatFunctionalMixin],

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
  },
  classNameMap: memoize(
    (props) => {
      return {
        [PARALLEL_DIFF_VIEW_TYPE]: !props.inline,
        commented: props.isCommented,
      };
    },
    (props) => [!props.inline, props.isCommented].join(':'),
  ),
  parallelViewLeftLineType: memoize(
    (props) => {
      return utils.parallelViewLeftLineType({
        line: props.line,
        highlighted: props.isHighlighted,
        commented: props.isCommented,
        selectionStart: props.isFirstHighlightedLine,
        selectionEnd: props.isLastHighlightedLine,
      });
    },
    (props) =>
      [
        props.line.left?.type,
        props.line.right?.type,
        props.isHighlighted,
        props.isCommented,
        props.isFirstHighlightedLine,
        props.isLastHighlightedLine,
      ].join(':'),
  ),
  coverageStateLeft: memoize(
    (props) => {
      if (!props.inline || !props.line.left) return {};
      return props.fileLineCoverage(props.filePath, props.line.left.new_line);
    },
    (props) =>
      [props.inline, props.filePath, props.line.left?.new_line, props.coverageLoaded].join(':'),
  ),
  coverageStateRight: memoize(
    (props) => {
      if (!props.line.right) return {};
      return props.fileLineCoverage(props.filePath, props.line.right.new_line);
    },
    (props) => [props.line.right?.new_line, props.filePath, props.coverageLoaded].join(':'),
  ),
  showCodequalityLeft: memoize(
    (props) => {
      return props.inline && props.line.left?.codequality?.length > 0;
    },
    (props) => [props.inline, props.line.left?.codequality?.length].join(':'),
  ),
  showCodequalityRight: memoize(
    (props) => {
      return !props.inline && props.line.right?.codequality?.length > 0;
    },
    (props) => [props.inline, props.line.right?.codequality?.length].join(':'),
  ),
  showSecurityLeft: memoize(
    (props) => {
      return props.inline && props.line.left?.sast?.length > 0;
    },
    (props) => [props.inline, props.line.left?.sast?.length].join(':'),
  ),
  showSecurityRight: memoize(
    (props) => {
      return !props.inline && props.line.right?.sast?.length > 0;
    },
    (props) => [props.inline, props.line.right?.sast?.length].join(':'),
  ),
  classNameMapCellLeft: memoize(
    (props) => {
      return utils.classNameMapCell({
        line: props.line?.left,
        highlighted: props.isHighlighted,
        commented: props.isCommented,
        selectionStart: props.isFirstHighlightedLine,
        selectionEnd: props.isLastHighlightedLine,
      });
    },
    (props) =>
      [
        props.line?.left?.type,
        props.isHighlighted,
        props.isCommented,
        props.isFirstHighlightedLine,
        props.isLastHighlightedLine,
      ].join(':'),
  ),
  classNameMapCellRight: memoize(
    (props) => {
      return utils.classNameMapCell({
        line: props.line?.right,
        highlighted: props.isHighlighted,
        commented: props.isCommented,
        selectionStart: props.isFirstHighlightedLine,
        selectionEnd: props.isLastHighlightedLine,
      });
    },
    (props) =>
      [
        props.line?.right?.type,
        props.isHighlighted,
        props.isCommented,
        props.isFirstHighlightedLine,
        props.isLastHighlightedLine,
      ].join(':'),
  ),
  shouldRenderCommentButton: memoize(
    (props, side) => {
      return (
        isLoggedIn() && !props.line[`isContextLine${side}`] && !props.line[`isMetaLine${side}`]
      );
    },
    (props, side) =>
      [props.line[`isContextLine${side}`], props.line[`isMetaLine${side}`]].join(':'),
  ),
  interopLeftAttributes(props) {
    if (props.inline) {
      return getInteropInlineAttributes(props.line.left);
    }

    return getInteropOldSideAttributes(props.line.left);
  },
  interopRightAttributes(props) {
    return getInteropNewSideAttributes(props.line.right);
  },
  lineContent: (line) => {
    if (line.isConflictMarker) {
      return line.type === CONFLICT_MARKER_THEIR ? 'HEAD//our changes' : 'origin//their changes';
    }

    return line.rich_text;
  },
  CONFLICT_MARKER,
  CONFLICT_MARKER_THEIR,
  CONFLICT_OUR,
  CONFLICT_THEIR,
};
</script>

<!-- eslint-disable-next-line vue/no-deprecated-functional-template -->
<template functional>
  <div
    :class="[
      $options.classNameMap(props),
      { expansion: props.line.left && props.line.left.type === 'expanded' },
    ]"
    class="diff-grid-row diff-tr line_holder"
  >
    <div
      :id="props.line.left && props.line.left.line_code"
      data-testid="left-side"
      class="diff-grid-left left-side"
      v-bind="$options.interopLeftAttributes(props)"
      @dragover.prevent
      @dragenter="listeners.enterdragging({ ...props.line.left, index: props.index })"
      @dragend="listeners.stopdragging"
    >
      <template v-if="props.line.left && props.line.left.type !== $options.CONFLICT_MARKER">
        <div
          :class="$options.classNameMapCellLeft(props)"
          data-testid="left-line-number"
          class="diff-td diff-line-num"
        >
          <span
            v-if="
              !props.line.left.isConflictMarker &&
              $options.shouldRenderCommentButton(props, 'Left') &&
              !props.line.hasDiscussionsLeft
            "
            class="add-diff-note tooltip-wrapper has-tooltip"
            :title="props.line.left.addCommentTooltip"
          >
            <div
              data-testid="left-comment-button"
              role="button"
              tabindex="0"
              :draggable="!props.line.left.commentsDisabled"
              type="button"
              class="add-diff-note unified-diff-components-diff-note-button note-button js-add-diff-note-button"
              :disabled="props.line.left.commentsDisabled"
              :aria-disabled="props.line.left.commentsDisabled"
              @click="
                !props.line.left.commentsDisabled &&
                  listeners.showCommentForm(props.line.left.line_code)
              "
              @keydown.enter="
                !props.line.left.commentsDisabled &&
                  listeners.showCommentForm(props.line.left.line_code)
              "
              @keydown.space="
                !props.line.left.commentsDisabled &&
                  listeners.showCommentForm(props.line.left.line_code)
              "
              @dragstart="
                !props.line.left.commentsDisabled &&
                  listeners.startdragging({
                    event: $event,
                    line: { ...props.line.left, index: props.index },
                  })
              "
            ></div>
          </span>
          <a
            v-if="props.line.left.old_line && props.line.left.type !== $options.CONFLICT_THEIR"
            :data-linenumber="props.line.left.old_line"
            :href="props.line.lineHrefOld"
            @click="listeners.setHighlightedRow({ lineCode: props.line.lineCode, event: $event })"
          >
          </a>
          <component
            :is="$options.DiffGutterAvatars"
            v-if="props.line.hasDiscussionsLeft"
            :discussions="props.line.left.discussions"
            :discussions-expanded="props.line.left.discussionsExpanded"
            data-testid="left-discussions"
            @toggleLineDiscussions="
              listeners.toggleLineDiscussions({
                lineCode: props.line.left.line_code,
                expanded: !props.line.left.discussionsExpanded,
              })
            "
          />
        </div>
        <div
          v-if="props.inline"
          :class="$options.classNameMapCellLeft(props)"
          class="diff-td diff-line-num"
        >
          <a
            v-if="props.line.left.new_line && props.line.left.type !== $options.CONFLICT_OUR"
            :data-linenumber="props.line.left.new_line"
            :href="props.line.lineHrefOld"
            @click="listeners.setHighlightedRow({ lineCode: props.line.lineCode, event: $event })"
          >
          </a>
        </div>
        <div
          :title="$options.coverageStateLeft(props).text"
          :data-tooltip-custom-class="$options.coverageStateLeft(props).class"
          :class="[
            $options.parallelViewLeftLineType(props),
            $options.coverageStateLeft(props).class,
          ]"
          class="diff-td line-coverage left-side has-tooltip"
        ></div>
        <div
          class="diff-td line-inline-findings left-side"
          :class="$options.parallelViewLeftLineType(props)"
        >
          <component
            :is="$options.InlineFindingsGutterIconDropdown"
            v-if="$options.showCodequalityLeft(props) || $options.showSecurityLeft(props)"
            :code-quality="props.line.left.codequality"
            :sast="props.line.left.sast"
            :file-path="props.filePath"
            @showInlineFindings="
              listeners.toggleCodeQualityFindings(
                props.line.left.codequality[0]
                  ? props.line.left.codequality[0].line
                  : props.line.left.sast[0].line,
              )
            "
          />
        </div>
        <div
          :key="props.line.left.line_code"
          :class="[
            $options.parallelViewLeftLineType(props),
            { parallel: !props.inline, 'gl-font-bold': props.line.left.isConflictMarker },
          ]"
          class="diff-td line_content with-coverage left-side"
          data-testid="left-content"
          v-html="
            $options.lineContent(props.line.left) /* v-html for performance, see top of file */
          "
        ></div>
      </template>
      <template
        v-else-if="
          !props.inline || (props.line.left && props.line.left.type === $options.CONFLICT_MARKER)
        "
      >
        <div
          data-testid="left-empty-cell"
          class="diff-td diff-line-num old_line empty-cell"
          :class="$options.classNameMapCellLeft(props)"
        >
          &nbsp;
        </div>
        <div
          class="diff-td line-coverage left-side empty-cell"
          :class="$options.classNameMapCellLeft(props)"
        ></div>
        <div
          class="diff-td line-inline-findings left-side empty-cell"
          :class="$options.classNameMapCellLeft(props)"
        ></div>
        <div
          class="diff-td line_content with-coverage left-side empty-cell"
          :class="[{ parallel: !props.inline }, ...$options.classNameMapCellLeft(props)]"
        ></div>
      </template>
    </div>
    <div
      v-if="!props.inline"
      :id="props.line.right && props.line.right.line_code"
      data-testid="right-side"
      class="diff-grid-right right-side"
      v-bind="$options.interopRightAttributes(props)"
      @dragover.prevent
      @dragenter="listeners.enterdragging({ ...props.line.right, index: props.index })"
      @dragend="listeners.stopdragging"
    >
      <template v-if="props.line.right">
        <div :class="$options.classNameMapCellRight(props)" class="diff-td diff-line-num new_line">
          <template v-if="props.line.right.type !== $options.CONFLICT_MARKER_THEIR">
            <span
              v-if="
                $options.shouldRenderCommentButton(props, 'Right') &&
                !props.line.hasDiscussionsRight
              "
              class="add-diff-note tooltip-wrapper has-tooltip"
              :title="props.line.right.addCommentTooltip"
            >
              <div
                data-testid="right-comment-button"
                role="button"
                tabindex="0"
                :draggable="!props.line.right.commentsDisabled"
                type="button"
                class="add-diff-note unified-diff-components-diff-note-button note-button js-add-diff-note-button"
                :disabled="props.line.right.commentsDisabled"
                :aria-disabled="props.line.right.commentsDisabled"
                @click="
                  !props.line.right.commentsDisabled &&
                    listeners.showCommentForm(props.line.right.line_code)
                "
                @keydown.enter="
                  !props.line.right.commentsDisabled &&
                    listeners.showCommentForm(props.line.right.line_code)
                "
                @keydown.space="
                  !props.line.right.commentsDisabled &&
                    listeners.showCommentForm(props.line.right.line_code)
                "
                @dragstart="
                  !props.line.right.commentsDisabled &&
                    listeners.startdragging({
                      event: $event,
                      line: { ...props.line.right, index: props.index },
                    })
                "
              ></div>
            </span>
          </template>
          <a
            v-if="props.line.right.new_line"
            :data-linenumber="props.line.right.new_line"
            :href="props.line.lineHrefNew"
            @click="listeners.setHighlightedRow({ lineCode: props.line.lineCode, event: $event })"
          >
          </a>
          <component
            :is="$options.DiffGutterAvatars"
            v-if="props.line.hasDiscussionsRight"
            :discussions="props.line.right.discussions"
            :discussions-expanded="props.line.right.discussionsExpanded"
            data-testid="right-discussions"
            @toggleLineDiscussions="
              listeners.toggleLineDiscussions({
                lineCode: props.line.right.line_code,
                expanded: !props.line.right.discussionsExpanded,
              })
            "
          />
        </div>
        <div
          :title="$options.coverageStateRight(props).text"
          :data-tooltip-custom-class="$options.coverageStateRight(props).class"
          :class="[
            props.line.right.type,
            $options.coverageStateRight(props).class,
            ...$options.classNameMapCellRight(props),
          ]"
          class="diff-td line-coverage right-side has-tooltip"
        ></div>
        <div
          class="diff-td line-inline-findings right-side"
          :class="$options.classNameMapCellRight(props)"
        >
          <component
            :is="$options.InlineFindingsGutterIconDropdown"
            v-if="$options.showCodequalityRight(props) || $options.showSecurityRight(props)"
            :code-quality="props.line.right.codequality"
            :sast="props.line.right.sast"
            :file-path="props.filePath"
            data-testid="inlineFindingsIcon"
            @showInlineFindings="
              listeners.toggleCodeQualityFindings(
                props.line.right.codequality[0]
                  ? props.line.right.codequality[0].line
                  : props.line.right.sast[0].line,
              )
            "
          />
        </div>
        <div
          :key="props.line.right.rich_text"
          :class="[
            props.line.right.type,
            {
              'gl-font-bold': props.line.right.type === $options.CONFLICT_MARKER_THEIR,
            },
            ...$options.classNameMapCellRight(props),
          ]"
          class="diff-td line_content with-coverage right-side parallel"
          v-html="
            $options.lineContent(props.line.right) /* v-html for performance, see top of file */
          "
        ></div>
      </template>
      <template v-else>
        <div
          data-testid="right-empty-cell"
          class="diff-td diff-line-num old_line empty-cell"
          :class="$options.classNameMapCellRight(props)"
        ></div>
        <div
          class="diff-td line-coverage right-side empty-cell"
          :class="$options.classNameMapCellRight(props)"
        ></div>
        <div
          class="diff-td line-inline-findings right-side empty-cell"
          :class="$options.classNameMapCellRight(props)"
        ></div>
        <div
          class="diff-td line_content with-coverage right-side empty-cell parallel"
          :class="$options.classNameMapCellRight(props)"
        ></div>
      </template>
    </div>
  </div>
</template>
