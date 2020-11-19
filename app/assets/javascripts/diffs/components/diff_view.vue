<script>
import { mapGetters, mapState } from 'vuex';
import draftCommentsMixin from '~/diffs/mixins/draft_comments';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import DiffRow from './diff_row.vue';
import DiffCommentCell from './diff_comment_cell.vue';
import DiffExpansionCell from './diff_expansion_cell.vue';
import { getCommentedLines } from '~/notes/components/multiline_comment_utils';

export default {
  components: {
    DiffExpansionCell,
    DiffRow,
    DiffCommentCell,
    DraftNote,
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
    inline: {
      type: Boolean,
      required: false,
      default: false,
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
  methods: {
    showCommentLeft(line) {
      return !this.inline || line.left;
    },
    showCommentRight(line) {
      return !this.inline || (line.right && !line.left);
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div
    :class="[$options.userColorScheme, { inline }]"
    :data-commit-id="commitId"
    class="diff-grid diff-table code diff-wrap-lines js-syntax-highlight text-file"
  >
    <template v-for="(line, index) in diffLines">
      <div
        v-if="line.isMatchLineLeft || line.isMatchLineRight"
        :key="`expand-${index}`"
        class="diff-tr line_expansion match"
      >
        <div class="diff-td text-center gl-font-regular">
          <diff-expansion-cell
            :file-hash="diffFile.file_hash"
            :context-lines-path="diffFile.context_lines_path"
            :line="line.left"
            :is-top="index === 0"
            :is-bottom="index + 1 === diffLinesLength"
          />
        </div>
      </div>
      <diff-row
        v-if="!line.isMatchLineLeft && !line.isMatchLineRight"
        :key="line.line_code"
        :file-hash="diffFile.file_hash"
        :file-path="diffFile.file_path"
        :line="line"
        :is-bottom="index + 1 === diffLinesLength"
        :is-commented="index >= commentedLines.startLine && index <= commentedLines.endLine"
        :inline="inline"
      />
      <div
        v-if="line.renderCommentRow"
        :key="`dcr-${line.line_code || index}`"
        :class="line.commentRowClasses"
        class="diff-grid-comments diff-tr notes_holder"
      >
        <div v-if="showCommentLeft(line)" class="diff-td notes-content parallel old">
          <diff-comment-cell
            v-if="line.left"
            :line="line.left"
            :diff-file-hash="diffFile.file_hash"
            :help-page-path="helpPagePath"
            :has-draft="line.left.hasDraft"
            line-position="left"
          />
        </div>
        <div v-if="showCommentRight(line)" class="diff-td notes-content parallel new">
          <diff-comment-cell
            v-if="line.right"
            :line="line.right"
            :diff-file-hash="diffFile.file_hash"
            :line-index="index"
            :help-page-path="helpPagePath"
            :has-draft="line.right.hasDraft"
            line-position="right"
          />
        </div>
      </div>
      <div
        v-if="shouldRenderParallelDraftRow(diffFile.file_hash, line)"
        :key="`drafts-${index}`"
        :class="line.draftRowClasses"
        class="diff-grid-drafts diff-tr notes_holder"
      >
        <div
          v-if="!inline || (line.left && line.left.lineDraft.isDraft)"
          class="diff-td notes-content parallel old"
        >
          <div v-if="line.left && line.left.lineDraft.isDraft" class="content">
            <draft-note :draft="line.left.lineDraft" :line="line.left" />
          </div>
        </div>
        <div
          v-if="!inline || (line.right && line.right.lineDraft.isDraft)"
          class="diff-td notes-content parallel new"
        >
          <div v-if="line.right && line.right.lineDraft.isDraft" class="content">
            <draft-note :draft="line.right.lineDraft" :line="line.right" />
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
