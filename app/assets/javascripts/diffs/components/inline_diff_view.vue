<script>
import { mapGetters, mapState } from 'vuex';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import draftCommentsMixin from '~/diffs/mixins/draft_comments';
import { getCommentedLines } from '~/notes/components/multiline_comment_utils';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DiffCommentCell from './diff_comment_cell.vue';
import DiffExpansionCell from './diff_expansion_cell.vue';
import inlineDiffTableRow from './inline_diff_table_row.vue';

export default {
  components: {
    DiffCommentCell,
    inlineDiffTableRow,
    DraftNote,
    DiffExpansionCell,
  },
  mixins: [draftCommentsMixin, glFeatureFlagsMixin()],
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
    class="code diff-wrap-lines js-syntax-highlight text-file js-diff-inline-view"
  >
    <colgroup>
      <col style="width: 50px" />
      <col style="width: 50px" />
      <col style="width: 8px" />
      <col />
    </colgroup>
    <tbody>
      <template v-for="(line, index) in diffLines">
        <tr v-if="line.isMatchLine" :key="`expand-${index}`" class="line_expansion match">
          <td colspan="4" class="text-center gl-font-regular">
            <diff-expansion-cell
              :file-hash="diffFile.file_hash"
              :context-lines-path="diffFile.context_lines_path"
              :line="line"
              :is-top="index === 0"
              :is-bottom="index + 1 === diffLinesLength"
            />
          </td>
        </tr>
        <inline-diff-table-row
          v-if="!line.isMatchLine"
          :key="`${line.line_code || index}`"
          :file-hash="diffFile.file_hash"
          :file-path="diffFile.file_path"
          :line="line"
          :is-bottom="index + 1 === diffLinesLength"
          :is-commented="index >= commentedLines.startLine && index <= commentedLines.endLine"
        />
        <tr
          v-if="line.renderCommentRow"
          :key="`icr-${line.line_code || index}`"
          :class="line.commentRowClasses"
          class="notes_holder"
        >
          <td class="notes-content" colspan="4">
            <diff-comment-cell
              :diff-file-hash="diffFile.file_hash"
              :line="line"
              :help-page-path="helpPagePath"
              :has-draft="line.hasDraft"
            />
          </td>
        </tr>
        <tr v-if="line.hasDraft" :key="`draft_${index}`" class="notes_holder js-temp-notes-holder">
          <td class="notes-content" colspan="4">
            <div class="content">
              <draft-note
                :draft="draftForLine(diffFile.file_hash, line)"
                :diff-file="diffFile"
                :line="line"
              />
            </div>
          </td>
        </tr>
      </template>
    </tbody>
  </table>
</template>
