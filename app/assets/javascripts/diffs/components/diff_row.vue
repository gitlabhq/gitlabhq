<script>
/* eslint-disable vue/no-v-html */
import { memoize } from 'lodash';
import { isLoggedIn } from '~/lib/utils/common_utils';
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
  CodeQualityGutterIcon: () => import('ee_component/diffs/components/code_quality_gutter_icon.vue'),
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
    isHighlighted: {
      type: Boolean,
      required: true,
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
      return utils.parallelViewLeftLineType(props.line, props.isHighlighted || props.isCommented);
    },
    (props) =>
      [props.line.left?.type, props.line.right?.type, props.isHighlighted, props.isCommented].join(
        ':',
      ),
  ),
  coverageStateLeft: memoize(
    (props) => {
      if (!props.inline || !props.line.left) return {};
      return props.fileLineCoverage(props.filePath, props.line.left.new_line);
    },
    (props) => [props.inline, props.filePath, props.line.left?.new_line].join(':'),
  ),
  coverageStateRight: memoize(
    (props) => {
      if (!props.line.right) return {};
      return props.fileLineCoverage(props.filePath, props.line.right.new_line);
    },
    (props) => [props.line.right?.new_line, props.filePath].join(':'),
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
  classNameMapCellLeft: memoize(
    (props) => {
      return utils.classNameMapCell({
        line: props.line.left,
        hll: props.isHighlighted || props.isCommented,
      });
    },
    (props) => [props.line.left.type, props.isHighlighted, props.isCommented].join(':'),
  ),
  classNameMapCellRight: memoize(
    (props) => {
      return utils.classNameMapCell({
        line: props.line.right,
        hll: props.isHighlighted || props.isCommented,
      });
    },
    (props) => [props.line.right.type, props.isHighlighted, props.isCommented].join(':'),
  ),
  shouldRenderCommentButton: memoize(
    (props) => {
      return isLoggedIn() && !props.line.isContextLineLeft && !props.line.isMetaLineLeft;
    },
    (props) => [props.line.isContextLineLeft, props.line.isMetaLineLeft].join(':'),
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
  conflictText: memoize(
    (line) => {
      return line.type === CONFLICT_MARKER_THEIR ? 'HEAD//our changes' : 'origin//their changes';
    },
    (line) => line.type,
  ),
  lineContent: memoize(
    (line) => {
      if (line.isConflictMarker) {
        return line.type === CONFLICT_MARKER_THEIR ? 'HEAD//our changes' : 'origin//their changes';
      }

      return line.rich_text;
    },
    (line) => line.line_code,
  ),
  CONFLICT_MARKER,
  CONFLICT_MARKER_THEIR,
  CONFLICT_OUR,
  CONFLICT_THEIR,
};
</script>

<!-- eslint-disable-next-line vue/no-deprecated-functional-template -->
<template functional>
  <div :class="$options.classNameMap(props)" class="diff-grid-row diff-tr line_holder">
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
          data-qa-selector="new_diff_line_link"
        >
          <span
            v-if="
              !props.line.left.isConflictMarker &&
              $options.shouldRenderCommentButton(props) &&
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
              data-qa-selector="diff_comment_button"
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
            @click="listeners.setHighlightedRow(props.line.lineCode)"
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
            @click="listeners.setHighlightedRow(props.line.lineCode)"
          >
          </a>
        </div>
        <div
          :title="$options.coverageStateLeft(props).text"
          :class="[
            $options.parallelViewLeftLineType(props),
            $options.coverageStateLeft(props).class,
          ]"
          class="diff-td line-coverage left-side has-tooltip"
        ></div>
        <div
          class="diff-td line-codequality left-side"
          :class="$options.parallelViewLeftLineType(props)"
        >
          <component
            :is="$options.CodeQualityGutterIcon"
            v-if="$options.showCodequalityLeft(props)"
            :codequality="props.line.left.codequality"
            :file-path="props.filePath"
          />
        </div>
        <div
          :key="props.line.left.line_code"
          :class="[
            $options.parallelViewLeftLineType(props),
            { parallel: !props.inline, 'gl-font-weight-bold': props.line.left.isConflictMarker },
          ]"
          class="diff-td line_content with-coverage left-side"
          data-testid="left-content"
          v-html="$options.lineContent(props.line.left)"
        ></div>
      </template>
      <template
        v-else-if="
          !props.inline || (props.line.left && props.line.left.type === $options.CONFLICT_MARKER)
        "
      >
        <div data-testid="left-empty-cell" class="diff-td diff-line-num old_line empty-cell">
          &nbsp;
        </div>
        <div v-if="props.inline" class="diff-td diff-line-num old_line empty-cell"></div>
        <div class="diff-td line-coverage left-side empty-cell"></div>
        <div v-if="props.inline" class="diff-td line-codequality left-side empty-cell"></div>
        <div
          class="diff-td line_content with-coverage left-side empty-cell"
          :class="[{ parallel: !props.inline }]"
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
              v-if="$options.shouldRenderCommentButton(props) && !props.line.hasDiscussionsRight"
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
            @click="listeners.setHighlightedRow(props.line.lineCode)"
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
          :class="[
            props.line.right.type,
            $options.coverageStateRight(props).class,
            { hll: props.isHighlighted, hll: props.isCommented },
          ]"
          class="diff-td line-coverage right-side has-tooltip"
        ></div>
        <div
          class="diff-td line-codequality right-side"
          :class="[props.line.right.type, { hll: props.isHighlighted, hll: props.isCommented }]"
        >
          <component
            :is="$options.CodeQualityGutterIcon"
            v-if="$options.showCodequalityRight(props)"
            :codequality="props.line.right.codequality"
            :file-path="props.filePath"
            data-testid="codeQualityIcon"
          />
        </div>
        <div
          :key="props.line.right.rich_text"
          :class="[
            props.line.right.type,
            {
              hll: props.isHighlighted,
              hll: props.isCommented,
              'gl-font-weight-bold': props.line.right.type === $options.CONFLICT_MARKER_THEIR,
            },
          ]"
          class="diff-td line_content with-coverage right-side parallel"
          v-html="$options.lineContent(props.line.right)"
        ></div>
      </template>
      <template v-else>
        <div data-testid="right-empty-cell" class="diff-td diff-line-num old_line empty-cell"></div>
        <div class="diff-td line-coverage right-side empty-cell"></div>
        <div class="diff-td line-codequality right-side empty-cell"></div>
        <div class="diff-td line_content with-coverage right-side empty-cell parallel"></div>
      </template>
    </div>
  </div>
</template>
