<script>
import { mapGetters } from 'vuex';
import parallelDiffTableRow from './parallel_diff_table_row.vue';
import parallelDiffCommentRow from './parallel_diff_comment_row.vue';
import { EMPTY_CELL_TYPE } from '../constants';
import { trimFirstCharOfLineContent } from '../store/utils';

export default {
  components: {
    parallelDiffTableRow,
    parallelDiffCommentRow,
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
    parallelDiffLines() {
      return this.diffLines.map(line => {
        if (line.left) {
          Object.assign(line, { left: trimFirstCharOfLineContent(line.left) });
        } else {
          Object.assign(line, { left: { type: EMPTY_CELL_TYPE } });
        }

        if (line.right) {
          Object.assign(line, { right: trimFirstCharOfLineContent(line.right) });
        } else {
          Object.assign(line, { right: { type: EMPTY_CELL_TYPE } });
        }

        return line;
      });
    },
    diffLinesLength() {
      return this.parallelDiffLines.length;
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
          <parallel-diff-table-row
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
