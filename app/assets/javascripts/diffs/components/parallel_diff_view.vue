<script>
import diffContentMixin from '../mixins/diff_content';
import parallelDiffCommentRow from './parallel_diff_comment_row.vue';
import { EMPTY_CELL_TYPE } from '../constants';

export default {
  components: {
    parallelDiffCommentRow,
  },
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
          v-for="(line, index) in parallelDiffLines"
        >
          <diff-table-row
            :diff-file="diffFile"
            :line="line"
            :is-bottom="index + 1 === diffLinesLength"
            :key="index"
          />
          <parallel-diff-comment-row
            :key="line.left.lineCode || line.right.lineCode"
            :line="line"
            :diff-file="diffFile"
            :diff-lines="parallelDiffLines"
            :line-index="index"
          />
        </template>
      </tbody>
    </table>
  </div>
</template>
