<script>
import { mapState, mapGetters } from 'vuex';
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
    ...mapGetters('diffs', [
      'commitId',
      'singleDiscussionByLineCode',
      'shouldRenderParallelCommentRow',
    ]),
    ...mapState({
      diffLineCommentForms: state => state.diffs.diffLineCommentForms,
    }),
    parallelDiffLines() {
      return this.diffLines.map(line => {
        const parallelLine = Object.assign({}, line);

        if (line.left) {
          parallelLine.left = trimFirstCharOfLineContent(line.left);
        } else {
          parallelLine.left = { type: EMPTY_CELL_TYPE };
        }

        if (line.right) {
          parallelLine.right = trimFirstCharOfLineContent(line.right);
        } else {
          parallelLine.right = { type: EMPTY_CELL_TYPE };
        }

        return parallelLine;
      });
    },
    diffLinesLength() {
      return this.parallelDiffLines.length;
    },
    userColorScheme() {
      return window.gon.user_color_scheme;
    },
  },
  methods: {
    discussionsByLine(line, leftOrRight) {
      return line[leftOrRight] && line[leftOrRight].lineCode !== undefined ?
            this.singleDiscussionByLineCode(line[leftOrRight].lineCode) : [];
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
            :file-hash="diffFile.fileHash"
            :context-lines-path="diffFile.contextLinesPath"
            :line="line"
            :is-bottom="index + 1 === diffLinesLength"
            :key="index"
            :left-discussions="discussionsByLine(line, 'left')"
            :right-discussions="discussionsByLine(line, 'right')"
          />
          <parallel-diff-comment-row
            v-if="shouldRenderParallelCommentRow(line)"
            :key="`dcr-${index}`"
            :line="line"
            :diff-file-hash="diffFile.fileHash"
            :line-index="index"
            :left-discussions="discussionsByLine(line, 'left')"
            :right-discussions="discussionsByLine(line, 'right')"
          />
        </template>
      </tbody>
    </table>
  </div>
</template>
