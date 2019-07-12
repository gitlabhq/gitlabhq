<script>
import { mapGetters } from 'vuex';
import draftCommentsMixin from 'ee_else_ce/diffs/mixins/draft_comments';
import inlineDiffTableRow from './inline_diff_table_row.vue';
import inlineDiffCommentRow from './inline_diff_comment_row.vue';

export default {
  components: {
    inlineDiffCommentRow,
    inlineDiffTableRow,
    InlineDraftCommentRow: () =>
      import('ee_component/batch_comments/components/inline_draft_comment_row.vue'),
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
    class="code diff-wrap-lines js-syntax-highlight text-file js-diff-inline-view"
  >
    <tbody>
      <template v-for="(line, index) in diffLines">
        <inline-diff-table-row
          :key="line.line_code"
          :file-hash="diffFile.file_hash"
          :context-lines-path="diffFile.context_lines_path"
          :line="line"
          :is-bottom="index + 1 === diffLinesLength"
        />
        <inline-diff-comment-row
          :key="`icr-${line.line_code || index}`"
          :diff-file-hash="diffFile.file_hash"
          :line="line"
          :help-page-path="helpPagePath"
          :has-draft="shouldRenderDraftRow(diffFile.file_hash, line) || false"
        />
        <inline-draft-comment-row
          v-if="shouldRenderDraftRow(diffFile.file_hash, line)"
          :key="`draft_${index}`"
          :draft="draftForLine(diffFile.file_hash, line)"
        />
      </template>
    </tbody>
  </table>
</template>
