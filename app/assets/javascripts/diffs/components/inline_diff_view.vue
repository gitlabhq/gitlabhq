<script>
import diffContentMixin from '../mixins/diff_content';
import {
  MATCH_LINE_TYPE,
  CONTEXT_LINE_TYPE,
  OLD_NO_NEW_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  LINE_HOVER_CLASS_NAME,
  LINE_UNFOLD_CLASS_NAME,
} from '../constants';

export default {
  mixins: [diffContentMixin],
  methods: {
    handleMouse(lineCode, isOver) {
      this.hoveredLineCode = isOver ? lineCode : null;
    },
    getLineClass(line) {
      const isSameLine = this.hoveredLineCode === line.lineCode;
      const isMatchLine = line.type === MATCH_LINE_TYPE;
      const isContextLine = line.type === CONTEXT_LINE_TYPE;
      const isMetaLine = line.type === OLD_NO_NEW_LINE_TYPE || line.type === NEW_NO_NEW_LINE_TYPE;

      return {
        [line.type]: line.type,
        [LINE_UNFOLD_CLASS_NAME]: this.isLoggedIn && isMatchLine,
        [LINE_HOVER_CLASS_NAME]:
          this.isLoggedIn && isSameLine && !isMatchLine && !isContextLine && !isMetaLine,
      };
    },
  },
};
</script>

<template>
  <table
    :class="userColorScheme"
    class="code diff-wrap-lines js-syntax-highlight text-file">
    <tbody>
      <template
        v-for="(line, index) in normalizedDiffLines"
      >
        <tr
          :id="line.lineCode"
          :key="line.lineCode"
          :class="getRowClass(line)"
          class="line_holder"
          @mouseover="handleMouse(line.lineCode, true)"
          @mouseout="handleMouse(line.lineCode, false)"
        >
          <td
            :class="getLineClass(line)"
            class="diff-line-num old_line"
          >
            <diff-line-gutter-content
              :file-hash="fileHash"
              :line-type="line.type"
              :line-code="line.lineCode"
              :line-number="line.oldLine"
              :meta-data="line.metaData"
              :show-comment-button="true"
              :context-lines-path="diffFile.contextLinesPath"
              :is-bottom="index + 1 === diffLinesLength"
              @showCommentForm="handleShowCommentForm"
            />
          </td>
          <td
            :class="getLineClass(line)"
            class="diff-line-num new_line"
          >
            <diff-line-gutter-content
              :file-hash="fileHash"
              :line-type="line.type"
              :line-code="line.lineCode"
              :line-number="line.newLine"
              :meta-data="line.metaData"
              :is-bottom="index + 1 === diffLinesLength"
              :context-lines-path="diffFile.contextLinesPath"
            />
          </td>
          <td
            :class="line.type"
            class="line_content"
            v-html="line.richText"
          >
          </td>
        </tr>
        <tr
          v-if="isDiscussionExpanded(line.lineCode) || diffLineCommentForms[line.lineCode]"
          :key="index"
          class="notes_holder"
        >
          <td
            class="notes_line"
            colspan="2"
          ></td>
          <td class="notes_content">
            <div class="content">
              <diff-discussions
                :notes="discussionsByLineCode[line.lineCode]"
              />
              <diff-line-note-form
                v-if="diffLineCommentForms[line.lineCode]"
                :diff-file="diffFile"
                :diff-lines="diffLines"
                :line="line"
                :note-target-line="diffLines[index]"
              />
            </div>
          </td>
        </tr>
      </template>
    </tbody>
  </table>
</template>
