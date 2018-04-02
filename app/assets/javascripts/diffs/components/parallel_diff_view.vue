<script>
import { mapState } from 'vuex';
import diffContentMixin from '../mixins/diff_content';
import {
  EMPTY_CELL_TYPE,
  MATCH_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  LINE_HOVER_CLASS_NAME,
  LINE_UNFOLD_CLASS_NAME,
  LINE_POSITION_RIGHT,
} from '../constants';

export default {
  mixins: [diffContentMixin],
  computed: {
    parallelDiffLines() {
      return this.normalizedDiffLines.map(line => {
        if (!line.left) {
          Object.assign(line, { left: { type: EMPTY_CELL_TYPE } });
        } else if (!line.right) {
          Object.assign(line, { right: { type: EMPTY_CELL_TYPE } });
        }

        return line;
      });
    },
  },
  methods: {
    hasDiscussion(line) {
      const discussions = this.discussionsByLineCode;
      const hasDiscussion = discussions[line.left.lineCode] || discussions[line.right.lineCode];

      return hasDiscussion;
    },
    getClassName(line, position) {
      const { type, lineCode } = line[position];
      const isMatchLine = type === MATCH_LINE_TYPE;
      const isContextLine = !isMatchLine && type !== EMPTY_CELL_TYPE && type !== CONTEXT_LINE_TYPE;
      const isMetaLine = type === OLD_NO_NEW_LINE_TYPE || type === NEW_NO_NEW_LINE_TYPE;
      const isSameLine = this.hoveredLineCode === lineCode;
      const isSameSection = position === this.hoveredSection;

      return {
        [type]: type,
        [LINE_UNFOLD_CLASS_NAME]: this.isLoggedIn && isMatchLine,
        [LINE_HOVER_CLASS_NAME]:
          this.isLoggedIn && isContextLine && isSameLine && isSameSection && !isMetaLine,
      };
    },
    handleMouse(e, line, isHover) {
      const cell = e.target.closest('td');

      if (isHover) {
        if (this.$refs.leftLines.indexOf(cell) > -1) {
          this.hoveredLineCode = line.left.lineCode;
          this.hoveredSection = 'left';
        } else if (this.$refs.rightLines.indexOf(cell) > -1) {
          this.hoveredLineCode = line.right.lineCode;
          this.hoveredSection = 'right';
        }
      } else {
        this.hoveredLineCode = null;
        this.hoveredSection = null;
      }
    },
    shouldRenderDiscussions(line, position) {
      const { lineCode, type } = line[position];
      let render = this.discussionsByLineCode[lineCode] && this.isDiscussionExpanded(lineCode);

      // Avoid rendering context line discussions on the right side in parallel view
      if (position === LINE_POSITION_RIGHT) {
        render = render && line.right.type;
      }

      return render;
    },
    hasAnyExpandedDiscussion(line) {
      const isLeftExpanded = this.isDiscussionExpanded(line.left.lineCode);
      const isRightExpanded = this.isDiscussionExpanded(line.right.lineCode);

      return isLeftExpanded || isRightExpanded;
    },
  },
};
</script>

<template>
  <div
    :class="userColorScheme"
    class="code diff-wrap-lines js-syntax-highlight text-file">
    <table>
      <tbody>
        <template
          v-for="(line, index) in parallelDiffLines"
        >
          <tr
            :key="index"
            :class="getRowClass(line)"
            class="line_holder parallel"
            @mouseover="handleMouse($event, line, true)"
            @mouseout="handleMouse($event, line, false)"
          >
            <td
              :class="getClassName(line, 'left')"
              ref="leftLines"
              class="diff-line-num old_line"
            >
              <diff-line-gutter-content
                :file-hash="fileHash"
                :line-type="line.left.type"
                :line-code="line.left.lineCode"
                :line-number="line.left.oldLine"
                :meta-data="line.left.metaData"
                :show-comment-button="true"
                :context-lines-path="diffFile.contextLinesPath"
                :is-bottom="index + 1 === diffLinesLength"
                line-position="left"
                @showCommentForm="handleShowCommentForm"
              />
            </td>
            <td
              :class="getClassName(line, 'left')"
              ref="leftLines"
              v-html="line.left.richText"
              class="line_content parallel left-side"
            >
            </td>
            <td
              :class="getClassName(line, 'right')"
              ref="rightLines"
              class="diff-line-num new_line"
            >
              <diff-line-gutter-content
                :file-hash="fileHash"
                :line-type="line.right.type"
                :line-code="line.right.lineCode"
                :line-number="line.right.newLine"
                :meta-data="line.right.metaData"
                :show-comment-button="true"
                :context-lines-path="diffFile.contextLinesPath"
                :is-bottom="index + 1 === diffLinesLength"
                line-position="right"
                @showCommentForm="handleShowCommentForm"
              />
            </td>
            <td
              :class="getClassName(line, 'right')"
              ref="rightLines"
              v-html="line.right.richText"
              class="line_content parallel right-side"
            >
            </td>
          </tr>
          <tr
            v-if="(
              (hasDiscussion(line) && hasAnyExpandedDiscussion(line)) ||
              diffLineCommentForms[line.left.lineCode] || diffLineCommentForms[line.right.lineCode]
            )"
            :key="line.left.lineCode || line.right.lineCode"
            class="notes_holder"
          >
            <td class="notes_line old"></td>
            <td class="notes_content parallel old">
              <div
                v-if="shouldRenderDiscussions(line, 'left')"
                class="content"
              >
                <diff-discussions
                  :notes="discussionsByLineCode[line.left.lineCode]"
                />
              </div>
              <diff-line-note-form
                v-if="diffLineCommentForms[line.left.lineCode] && diffLineCommentForms[line.left.lineCode]"
                :diff-file="diffFile"
                :diff-lines="diffLines"
                :line="line.left"
                :note-target-line="diffLines[index].left"
                position="left"
              />
            </td>
            <td class="notes_line new"></td>
            <td class="notes_content parallel new">
              <div
                v-if="shouldRenderDiscussions(line, 'right')"
                class="content"
              >
                <diff-discussions
                  :notes="discussionsByLineCode[line.right.lineCode]"
                />
              </div>
              <diff-line-note-form
                v-if="diffLineCommentForms[line.right.lineCode] && diffLineCommentForms[line.right.lineCode] && line.right.type"
                :diff-file="diffFile"
                :diff-lines="diffLines"
                :line="line.right"
                :note-target-line="diffLines[index].right"
                position="right"
              />
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
