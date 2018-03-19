<script>
import diffContentMixin from '../mixins/diff_content';
import { MATCH_LINE_TYPE, LINE_HOVER_CLASS_NAME } from '../constants';

export default {
  mixins: [diffContentMixin],
  methods: {
    handleMouse(lineCode, isOver) {
      this.hoveredLineCode = isOver ? lineCode : null;
    },
    getLineClass(line) {
      const isSameLine = this.hoveredLineCode === line.lineCode;
      const isMatchLine = line.type === MATCH_LINE_TYPE;

      return {
        [line.type]: true,
        [LINE_HOVER_CLASS_NAME]: isSameLine && !isMatchLine,
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
          :class="line.type"
          class="line_holder"
          @mouseover="handleMouse(line.lineCode, true)"
          @mouseout="handleMouse(line.lineCode, false)"
        >
          <td
            :class="getLineClass(line)"
            class="diff-line-num old_line"
          >
            <diff-line-gutter-content
              :line-type="line.type"
              :line-code="line.lineCode"
              :line-number="line.oldLine"
              :show-comment-button="true"
              @showCommentForm="handleShowCommentForm"
            />
          </td>
          <td
            :class="getLineClass(line)"
            class="diff-line-num new_line"
          >
            <diff-line-gutter-content
              :line-type="line.type"
              :line-code="line.lineCode"
              :line-number="line.newLine"
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
          v-if="discussionsByLineCode[line.lineCode]"
          :key="discussionsByLineCode[line.lineCode].id"
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
            </div>
          </td>
        </tr>
        <tr
          v-if="line.type === 'commentForm'"
          :key="line.id"
          class="notes_holder js-temp-notes-holder"
        >
          <td
            class="notes_line"
            colspan="2"
          ></td>
          <td class="notes_content">
            <diff-line-note-form
              :diff-file="diffFile"
              :diff-lines="diffLines"
              :line="line"
              :note-target-line="diffLines[index - 1]"
            />
          </td>
        </tr>
      </template>
    </tbody>
  </table>
</template>
