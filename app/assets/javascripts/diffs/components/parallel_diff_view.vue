<script>
import { mapGetters } from 'vuex';
import draftCommentsMixin from 'ee_else_ce/diffs/mixins/draft_comments';
import parallelDiffTableRow from './parallel_diff_table_row.vue';
import parallelDiffCommentRow from './parallel_diff_comment_row.vue';
import parallelDiffExpansionRow from './parallel_diff_expansion_row.vue';

export default {
  components: {
    parallelDiffExpansionRow,
    parallelDiffTableRow,
    parallelDiffCommentRow,
    ParallelDraftCommentRow: () =>
      import('ee_component/batch_comments/components/parallel_draft_comment_row.vue'),
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
    diffLinesLength() {
      return this.diffLines.length;
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
    <!-- Need to insert an empty row to solve "table-layout:fixed" equal width when expansion row is the first line -->
    <tr>
      <td style="width: 50px;"></td>
      <td></td>
      <td style="width: 50px;"></td>
      <td></td>
    </tr>
    <tbody>
      <template v-for="(line, index) in diffLines">
        <parallel-diff-expansion-row
          :key="`expand-${index}`"
          :file-hash="diffFile.file_hash"
          :context-lines-path="diffFile.context_lines_path"
          :line="line"
          :is-top="index === 0"
          :is-bottom="index + 1 === diffLinesLength"
        />
        <parallel-diff-table-row
          :key="line.line_code"
          :file-hash="diffFile.file_hash"
          :context-lines-path="diffFile.context_lines_path"
          :line="line"
          :is-bottom="index + 1 === diffLinesLength"
        />
        <parallel-diff-comment-row
          :key="`dcr-${line.line_code || index}`"
          :line="line"
          :diff-file-hash="diffFile.file_hash"
          :line-index="index"
          :help-page-path="helpPagePath"
          :has-draft-left="hasParallelDraftLeft(diffFile.file_hash, line) || false"
          :has-draft-right="hasParallelDraftRight(diffFile.file_hash, line) || false"
        />
        <parallel-draft-comment-row
          v-if="shouldRenderParallelDraftRow(diffFile.file_hash, line)"
          :key="`drafts-${index}`"
          :line="line"
          :diff-file-content-sha="diffFile.file_hash"
        />
      </template>
    </tbody>
  </table>
</template>
