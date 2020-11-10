<script>
import { mapGetters, mapState } from 'vuex';
import draftCommentsMixin from '~/diffs/mixins/draft_comments';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import parallelDiffTableRow from './parallel_diff_table_row.vue';
import DiffCommentCell from './diff_comment_cell.vue';
import DiffExpansionCell from './diff_expansion_cell.vue';
import { getCommentedLines } from '~/notes/components/multiline_comment_utils';

export default {
  components: {
    DiffExpansionCell,
    parallelDiffTableRow,
    DiffCommentCell,
    DraftNote,
  },
  mixins: [draftCommentsMixin],
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    diffLines: {
      type: Array,
      required: true,
    },
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapGetters('diffs', ['commitId']),
    ...mapState({
      selectedCommentPosition: ({ notes }) => notes.selectedCommentPosition,
      selectedCommentPositionHover: ({ notes }) => notes.selectedCommentPositionHover,
    }),
    diffLinesLength() {
      return this.diffLines.length;
    },
    commentedLines() {
      return getCommentedLines(
        this.selectedCommentPosition || this.selectedCommentPositionHover,
        this.diffLines,
      );
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <table
    :class="$options.userColorScheme"
    :data-commit-id="commitId"
    class="code diff-wrap-lines js-syntax-highlight text-file"
  >
    <colgroup>
      <col style="width: 50px;" />
      <col style="width: 8px;" />
      <col />
      <col style="width: 50px;" />
      <col style="width: 8px;" />
      <col />
    </colgroup>
    <tbody>
      <template v-for="(line, index) in diffLines">
        <tr
          v-if="line.isMatchLineLeft || line.isMatchLineRight"
          :key="`expand-${index}`"
          class="line_expansion match"
        >
          <td colspan="6" class="text-center gl-font-regular">
            <diff-expansion-cell
              :file-hash="diffFile.file_hash"
              :context-lines-path="diffFile.context_lines_path"
              :line="line.left"
              :is-top="index === 0"
              :is-bottom="index + 1 === diffLinesLength"
            />
          </td>
        </tr>
        <parallel-diff-table-row
          :key="line.line_code"
          :file-hash="diffFile.file_hash"
          :file-path="diffFile.file_path"
          :line="line"
          :is-bottom="index + 1 === diffLinesLength"
          :is-commented="index >= commentedLines.startLine && index <= commentedLines.endLine"
        />
        <tr
          v-if="line.renderCommentRow"
          :key="`dcr-${line.line_code || index}`"
          :class="line.commentRowClasses"
          class="notes_holder"
        >
          <td class="notes-content parallel old" colspan="3">
            <diff-comment-cell
              v-if="line.left"
              :line="line.left"
              :diff-file-hash="diffFile.file_hash"
              :help-page-path="helpPagePath"
              :has-draft="line.left.hasDraft"
              line-position="left"
            />
          </td>
          <td class="notes-content parallel new" colspan="3">
            <diff-comment-cell
              v-if="line.right"
              :line="line.right"
              :diff-file-hash="diffFile.file_hash"
              :line-index="index"
              :help-page-path="helpPagePath"
              :has-draft="line.right.hasDraft"
              line-position="right"
            />
          </td>
        </tr>
        <tr
          v-if="shouldRenderParallelDraftRow(diffFile.file_hash, line)"
          :key="`drafts-${index}`"
          :class="line.draftRowClasses"
          class="notes_holder"
        >
          <td class="notes_line old"></td>
          <td class="notes-content parallel old" colspan="2">
            <div v-if="line.left && line.left.lineDraft.isDraft" class="content">
              <draft-note :draft="line.left.lineDraft" :line="line.left" />
            </div>
          </td>
          <td class="notes_line new"></td>
          <td class="notes-content parallel new" colspan="2">
            <div v-if="line.right && line.right.lineDraft.isDraft" class="content">
              <draft-note :draft="line.right.lineDraft" :line="line.right" />
            </div>
          </td>
        </tr>
      </template>
    </tbody>
  </table>
</template>
