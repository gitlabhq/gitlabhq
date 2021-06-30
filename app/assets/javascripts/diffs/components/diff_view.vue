<script>
import { mapGetters, mapState, mapActions } from 'vuex';
import { IdState } from 'vendor/vue-virtual-scroller';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import draftCommentsMixin from '~/diffs/mixins/draft_comments';
import { getCommentedLines } from '~/notes/components/multiline_comment_utils';
import { hide } from '~/tooltips';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import DiffCommentCell from './diff_comment_cell.vue';
import DiffExpansionCell from './diff_expansion_cell.vue';
import DiffRow from './diff_row.vue';
import { isHighlighted } from './diff_row_utils';

export default {
  components: {
    DiffExpansionCell,
    DiffRow,
    DiffCommentCell,
    DraftNote,
  },
  mixins: [
    draftCommentsMixin,
    glFeatureFlagsMixin(),
    IdState({ idProp: (vm) => vm.diffFile.file_hash }),
  ],
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
  idState() {
    return {
      dragStart: null,
      updatedLineRange: null,
    };
  },
  computed: {
    ...mapGetters('diffs', ['commitId', 'fileLineCoverage']),
    ...mapState('diffs', ['codequalityDiff', 'highlightedRow']),
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
    hasCodequalityChanges() {
      return (
        this.glFeatures.codequalityMrDiffAnnotations &&
        this.codequalityDiff?.files?.[this.diffFile.file_path]?.length > 0
      );
    },
  },
  methods: {
    ...mapActions(['setSelectedCommentPosition']),
    ...mapActions('diffs', ['showCommentForm', 'setHighlightedRow', 'toggleLineDiscussions']),
    showCommentLeft(line) {
      return line.left && !line.right;
    },
    showCommentRight(line) {
      return line.right && !line.left;
    },
    onStartDragging({ event = {}, line }) {
      if (event.target?.parentNode) {
        hide(event.target.parentNode);
      }
      this.idState.dragStart = line;
    },
    onDragOver(line) {
      if (line.chunk !== this.idState.dragStart.chunk) return;

      let start = this.idState.dragStart;
      let end = line;

      if (this.idState.dragStart.index >= line.index) {
        start = line;
        end = this.idState.dragStart;
      }

      this.idState.updatedLineRange = { start, end };

      this.setSelectedCommentPosition(this.idState.updatedLineRange);
    },
    onStopDragging() {
      this.showCommentForm({
        lineCode: this.idState.updatedLineRange?.end?.line_code,
        fileHash: this.diffFile.file_hash,
      });
      this.idState.dragStart = null;
    },
    isHighlighted(line) {
      return isHighlighted(
        this.highlightedRow,
        line.left?.line_code ? line.left : line.right,
        false,
      );
    },
    handleParallelLineMouseDown(e) {
      const line = e.target.closest('.diff-td');
      const table = line.closest('.diff-table');

      table.classList.remove('left-side-selected', 'right-side-selected');
      const [lineClass] = ['left-side', 'right-side'].filter((name) =>
        line.classList.contains(name),
      );

      if (lineClass) {
        table.classList.add(`${lineClass}-selected`);
      }
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div
    :class="[$options.userColorScheme, { inline, 'with-codequality': hasCodequalityChanges }]"
    :data-commit-id="commitId"
    class="diff-grid diff-table code diff-wrap-lines js-syntax-highlight text-file"
    @mousedown="handleParallelLineMouseDown"
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
        :is-highlighted="isHighlighted(line)"
        :file-line-coverage="fileLineCoverage"
        @showCommentForm="(lineCode) => showCommentForm({ lineCode, fileHash: diffFile.file_hash })"
        @setHighlightedRow="setHighlightedRow"
        @toggleLineDiscussions="
          ({ lineCode, expanded }) =>
            toggleLineDiscussions({ lineCode, fileHash: diffFile.file_hash, expanded })
        "
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
