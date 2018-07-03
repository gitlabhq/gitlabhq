<script>
import diffContentMixin from '../mixins/diff_content';
import inlineDiffCommentRow from './inline_diff_comment_row.vue';

export default {
  components: {
    inlineDiffCommentRow,
  },
  mixins: [diffContentMixin],
};
</script>

<template>
  <table
    :class="userColorScheme"
    :data-commit-id="commitId"
    class="code diff-wrap-lines js-syntax-highlight text-file js-diff-inline-view">
    <tbody>
      <template
        v-for="(line, index) in normalizedDiffLines"
      >
        <diff-table-row
          :diff-file="diffFile"
          :line="line"
          :is-bottom="index + 1 === diffLinesLength"
          :key="line.lineCode"
        />
        <inline-diff-comment-row
          :diff-file="diffFile"
          :diff-lines="normalizedDiffLines"
          :line="line"
          :line-index="index"
          :key="index"
        />
      </template>
    </tbody>
  </table>
</template>
