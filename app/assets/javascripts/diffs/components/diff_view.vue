<script>
import { mapGetters, mapState, mapActions } from 'vuex';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import draftCommentsMixin from '~/diffs/mixins/draft_comments';
import { getCommentedLines } from '~/notes/components/multiline_comment_utils';
import DiffCommentCell from './diff_comment_cell.vue';
import DiffExpansionCell from './diff_expansion_cell.vue';
import DiffRow from './diff_row.vue';

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
  data() {
    return {
      dragStart: null,
      updatedLineRange: null,
    };
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
    ...mapActions(['setSelectedCommentPosition']),
    ...mapActions('diffs', ['showCommentForm']),
    showCommentLeft(line) {
      return line.left && !line.right;
    },
    showCommentRight(line) {
      return line.right && !line.left;
    },
    onStartDragging(line) {
      this.dragStart = line;
    },
    onDragOver(line) {
      if (line.chunk !== this.dragStart.chunk) return;

      let start = this.dragStart;
      let end = line;

      if (this.dragStart.index >= line.index) {
        start = line;
        end = this.dragStart;
      }

      this.updatedLineRange = { start, end };

      this.setSelectedCommentPosition(this.updatedLineRange);
    },
    onStopDragging() {
      this.showCommentForm({
        lineCode: this.updatedLineRange?.end?.line_code,
        fileHash: this.diffFile.file_hash,
      });
      this.dragStart = null;
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
        :index="index"
        @enterdragging="onDragOver"
        @startdragging="onStartDragging"
        @stopdragging="onStopDragging"
      />
      <div
        v-if="line.renderCommentRow"
        :key="`dcr-${line.line_code || index}`"
        :class="line.commentRowClasses"
        class="diff-grid-comments diff-tr notes_holder"
      >
        <div
          v-if="line.left || !inline"
          :class="{ parallel: !inline }"
          class="diff-td notes-content old"
        >
          <diff-comment-cell
            v-if="line.left && (line.left.renderDiscussion || line.left.hasCommentForm)"
            :line="line.left"
            :diff-file-hash="diffFile.file_hash"
            :help-page-path="helpPagePath"
            line-position="left"
          />
        </div>
        <div
          v-if="line.right || !inline"
          :class="{ parallel: !inline }"
          class="diff-td notes-content new"
        >
          <diff-comment-cell
            v-if="line.right && (line.right.renderDiscussion || line.right.hasCommentForm)"
            :line="line.right"
            :diff-file-hash="diffFile.file_hash"
            :line-index="index"
            :help-page-path="helpPagePath"
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
