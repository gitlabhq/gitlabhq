<script>
import { mapState, mapGetters } from 'vuex';
import ParallelDraftCommentRow from 'ee/batch_comments/components/parallel_draft_comment_row.vue';
import parallelDiffTableRow from './parallel_diff_table_row.vue';
import parallelDiffCommentRow from './parallel_diff_comment_row.vue';

export default {
  components: {
    parallelDiffTableRow,
    parallelDiffCommentRow,
    ParallelDraftCommentRow,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    diffLines: {
      type: Array,
      required: true,
    },
  },
  computed: {
    ...mapGetters('diffs', ['commitId', 'shouldRenderParallelCommentRow']),
    ...mapGetters('batchComments', ['shouldRenderParallelDraftRow', 'draftForLine']),
    ...mapState({
      diffLineCommentForms: state => state.diffs.diffLineCommentForms,
    }),
    diffLinesLength() {
      return this.diffLines.length;
    },
    userColorScheme() {
      return window.gon.user_color_scheme;
    },
  },
};
</script>

<template>
  <div
    :class="userColorScheme"
    :data-commit-id="commitId"
    class="code diff-wrap-lines js-syntax-highlight text-file"
  >
    <table>
      <tbody>
        <template
          v-for="(line, index) in diffLines"
        >
          <parallel-diff-table-row
            :key="index"
            :file-hash="diffFile.fileHash"
            :context-lines-path="diffFile.contextLinesPath"
            :line="line"
            :is-bottom="index + 1 === diffLinesLength"
          />
          <parallel-diff-comment-row
            v-if="shouldRenderParallelCommentRow(line)"
            :key="`dcr-${index}`"
            :line="line"
            :diff-file-hash="diffFile.fileHash"
            :line-index="index"
          />
          <parallel-draft-comment-row
            v-if="shouldRenderParallelDraftRow(diffFile.fileHash, line)"
            :key="`drafts-${index}`"
            :line="line"
            :diff-file-content-sha="diffFile.fileHash"
          />
        </template>
      </tbody>
    </table>
  </div>
</template>
