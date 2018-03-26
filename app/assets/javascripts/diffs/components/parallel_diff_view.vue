<script>
import diffContentMixin from '../mixins/diff_content';
import {
  EMPTY_CELL_TYPE,
  MATCH_LINE_TYPE,
  LINE_HOVER_CLASS_NAME,
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

      return (
        discussions[line.left.lineCode] || discussions[line.right.lineCode]
      );
    },
    getClassName(line, position) {
      const { type, lineCode } = line[position];
      const isContextLine =
        type !== MATCH_LINE_TYPE && type !== EMPTY_CELL_TYPE;
      const isSameLine = this.hoveredLineCode === lineCode;
      const isSameSection = position === this.hoveredSection;

      return {
        [type]: type,
        [LINE_HOVER_CLASS_NAME]: isContextLine && isSameLine && isSameSection,
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
                :line-type="line.left.type"
                :line-code="line.left.lineCode"
                :line-number="line.left.oldLine"
                :show-comment-button="true"
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
                :line-type="line.right.type"
                :line-code="line.right.lineCode"
                :line-number="line.right.newLine"
                :show-comment-button="true"
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
            v-if="hasDiscussion(line)"
            :key="line.left.lineCode || line.right.lineCode"
            class="notes_holder"
          >
            <td class="notes_line old"></td>
            <td class="notes_content parallel old">
              <div
                v-if="discussionsByLineCode[line.left.lineCode]"
                class="content"
              >
                <diff-discussions
                  :notes="discussionsByLineCode[line.left.lineCode]"
                />
              </div>
            </td>
            <td class="notes_line new"></td>
            <td class="notes_content parallel new">
              <div
                v-if="discussionsByLineCode[line.right.lineCode] && line.right.type"
                class="content"
              >
                <diff-discussions
                  :notes="discussionsByLineCode[line.right.lineCode]"
                />
              </div>
            </td>
          </tr>
          <tr
            v-if="line.left.type === 'commentForm' || line.right.type === 'commentForm'"
            :key="line.id"
            class="notes_holder js-temp-notes-holder">
            <td class="notes_line old"></td>
            <td class="notes_content parallel old">
              <diff-line-note-form
                v-if="line.left.type === 'commentForm'"
                :diff-file="diffFile"
                :diff-lines="diffLines"
                :line="line.left"
                :note-target-line="diffLines[index - 1].left"
                position="left"
              />
            </td>
            <td class="notes_line new"></td>
            <td class="notes_content parallel new">
              <diff-line-note-form
                v-if="line.right.type === 'commentForm'"
                :diff-file="diffFile"
                :diff-lines="diffLines"
                :line="line.right"
                :note-target-line="diffLines[index - 1].right"
                position="right"
              />
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>
