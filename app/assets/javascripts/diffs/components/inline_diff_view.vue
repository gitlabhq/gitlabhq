<script>
import { mapGetters } from 'vuex';
import inlineDiffTableRow from './inline_diff_table_row.vue';
import inlineDiffCommentRow from './inline_diff_comment_row.vue';
import { trimFirstCharOfLineContent } from '../store/utils';

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
    ...mapGetters(['commit']),
    normalizedDiffLines() {
      return this.diffLines.map(line => (line.richText ? trimFirstCharOfLineContent(line) : line));
    },
    diffLinesLength() {
      return this.normalizedDiffLines.length;
    },
    commitId() {
      return this.commit && this.commit.id;
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
        v-for="(line, index) in normalizedDiffLines"
      >
        <inline-diff-table-row
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
