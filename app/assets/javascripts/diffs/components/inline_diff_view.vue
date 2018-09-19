<script>
import { mapGetters, mapState } from 'vuex';
import inlineDiffTableRow from './inline_diff_table_row.vue';
import inlineDiffCommentRow from './inline_diff_comment_row.vue';

export default {
  components: {
    inlineDiffCommentRow,
    inlineDiffTableRow,
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
    ...mapGetters('diffs', ['commitId', 'shouldRenderInlineCommentRow']),
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
  <table
    :class="userColorScheme"
    :data-commit-id="commitId"
    class="code diff-wrap-lines js-syntax-highlight text-file js-diff-inline-view">
    <tbody>
      <template
        v-for="(line, index) in diffLines"
      >
        <inline-diff-table-row
          :file-hash="diffFile.fileHash"
          :context-lines-path="diffFile.contextLinesPath"
          :line="line"
          :is-bottom="index + 1 === diffLinesLength"
          :key="line.lineCode"
        />
        <inline-diff-comment-row
          v-if="shouldRenderInlineCommentRow(line)"
          :diff-file-hash="diffFile.fileHash"
          :line="line"
          :line-index="index"
          :key="index"
        />
      </template>
    </tbody>
  </table>
</template>
