<script>
// eslint-disable-next-line no-restricted-imports
import { mapGetters, mapState, mapActions } from 'vuex';
import { throttle } from 'lodash';
import { IdState } from 'vendor/vue-virtual-scroller';
import DraftNote from '~/batch_comments/components/draft_note.vue';
import draftCommentsMixin from '~/diffs/mixins/draft_comments';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { getCommentedLines } from '~/notes/components/multiline_comment_utils';
import { hide } from '~/tooltips';
import { countLinesInBetween } from '~/diffs/utils/diff_file';
import { pickDirection } from '../utils/diff_line';
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
    IdState({ idProp: (vm) => vm.diffFile.file_hash }),
    glFeatureFlagsMixin(),
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
    codequalityData: {
      type: Object,
      required: false,
      default: null,
    },
    sastData: {
      type: Object,
      required: false,
      default: null,
    },
    autosaveKey: {
      type: String,
      required: false,
      default: '',
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
    ...mapState('diffs', ['highlightedRow', 'coverageLoaded', 'selectedCommentPosition']),
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
    hasInlineFindingsChanges() {
      return (
        this.codequalityData?.files?.[this.diffFile.file_path]?.length > 0 ||
        this.sastData?.added?.length > 0
      );
    },
  },
  created() {
    this.onDragOverThrottled = throttle((line) => this.onDragOver(line), 100, { leading: true });
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
    singleLineComment(code, line) {
      const lineDir = pickDirection({ line, code });

      this.idState.updatedLineRange = {
        start: lineDir,
        end: lineDir,
      };

      this.showCommentForm({ lineCode: lineDir.line_code, fileHash: this.diffFile.file_hash });
    },
    isHighlighted(line) {
      return isHighlighted(
        this.highlightedRow,
        line.left?.line_code ? line.left : line.right,
        false,
      );
    },
    isFirstHighlightedLine(line) {
      const lineCode = line.left?.line_code || line.right?.line_code;
      return lineCode && lineCode === this.selectedCommentPosition?.start.line_code;
    },
    isLastHighlightedLine(line) {
      const lineCode = line.left?.line_code || line.right?.line_code;
      return lineCode && lineCode === this.selectedCommentPosition?.end.line_code;
    },
    handleParallelLineMouseDown(e) {
      const line = e.target.closest('.diff-td');
      if (line) {
        const table = line.closest('.diff-table');
        table.classList.remove('left-side-selected', 'right-side-selected');
        const [lineClass] = ['left-side', 'right-side'].filter((name) =>
          line.classList.contains(name),
        );

        if (lineClass) {
          table.classList.add(`${lineClass}-selected`);
        }
      }
    },
    getCountBetweenIndex(index) {
      return countLinesInBetween(this.diffLines, index);
    },
    getCodeQualityLine(line) {
      return (
        (line.left ?? line.right)?.codequality?.[0]?.line ||
        (line.left ?? line.right)?.sast?.[0]?.line
      );
    },
    lineDrafts(line, side) {
      return (line[side]?.lineDrafts || []).filter((entry) => entry.isDraft);
    },
    lineHasDrafts(line, side) {
      return this.lineDrafts(line, side).length > 0;
    },
  },
  userColorScheme: window.gon.user_color_scheme,
};
</script>

<template>
  <div
    :class="[
      $options.userColorScheme,
      { 'inline-diff-view': inline, 'with-inline-findings': hasInlineFindingsChanges },
    ]"
    :data-commit-id="commitId"
    class="diff-grid diff-table code diff-wrap-lines js-syntax-highlight text-file"
    @mousedown="handleParallelLineMouseDown"
  >
    <template v-for="(line, index) in diffLines">
      <div
        v-if="line.isMatchLineLeft || line.isMatchLineRight"
        :key="`expand-${index}`"
        class="diff-grid-row diff-tr line_holder match expansion"
      >
        <diff-expansion-cell
          :file="diffFile"
          :line="line.left"
          :is-top="index === 0"
          :is-bottom="index + 1 === diffLinesLength"
          :inline="inline"
          :line-count-between="getCountBetweenIndex(index)"
          :class="{ parallel: !inline }"
          class="diff-grid-left diff-grid-2-col left-side"
        />
        <diff-expansion-cell
          v-if="!inline"
          :file="diffFile"
          :line="line.left"
          :is-top="index === 0"
          :is-bottom="index + 1 === diffLinesLength"
          :inline="inline"
          :line-count-between="getCountBetweenIndex(index)"
          :class="{ parallel: !inline }"
          class="diff-grid-right diff-grid-2-col right-side"
        />
      </div>
      <diff-row
        v-if="!line.isMatchLineLeft && !line.isMatchLineRight"
        :key="line.lineCode"
        :file-hash="diffFile.file_hash"
        :file-path="diffFile.file_path"
        :line="line"
        :is-bottom="index + 1 === diffLinesLength"
        :is-commented="index >= commentedLines.startLine && index <= commentedLines.endLine"
        :is-highlighted="isHighlighted(line)"
        :is-first-highlighted-line="
          isFirstHighlightedLine(line) || index === commentedLines.startLine
        "
        :is-last-highlighted-line="isLastHighlightedLine(line) || index === commentedLines.endLine"
        :inline="inline"
        :index="index"
        :file-line-coverage="fileLineCoverage"
        :coverage-loaded="coverageLoaded"
        @showCommentForm="(code) => singleLineComment(code, line)"
        @setHighlightedRow="setHighlightedRow"
        @toggleLineDiscussions="
          ({ lineCode, expanded }) =>
            toggleLineDiscussions({ lineCode, fileHash: diffFile.file_hash, expanded })
        "
        @enterdragging="onDragOverThrottled"
        @startdragging="onStartDragging"
        @stopdragging="onStopDragging"
      />
      <div
        v-if="line.renderCommentRow"
        :key="`dcr-${line.lineCode}`"
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
            :line-range="idState.updatedLineRange"
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
            :line-range="idState.updatedLineRange"
            :diff-file-hash="diffFile.file_hash"
            :line-index="index"
            :help-page-path="helpPagePath"
            line-position="right"
          />
        </div>
      </div>
      <div
        v-if="shouldRenderParallelDraftRow(diffFile.file_hash, line)"
        :key="`drafts-${line.lineCode}`"
        :class="line.draftRowClasses"
        class="diff-grid-drafts diff-tr notes_holder"
      >
        <div
          v-if="!inline || lineHasDrafts(line, 'left')"
          class="diff-td notes-content parallel old"
        >
          <div v-for="draft in lineDrafts(line, 'left')" :key="draft.id" class="content">
            <article class="note-wrapper">
              <ul class="notes draft-notes">
                <draft-note :draft="draft" :line="line.left" :autosave-key="autosaveKey" />
              </ul>
            </article>
          </div>
        </div>
        <div
          v-if="!inline || lineHasDrafts(line, 'right')"
          class="diff-td notes-content parallel new"
        >
          <div v-for="draft in lineDrafts(line, 'right')" :key="draft.id" class="content">
            <article class="note-wrapper">
              <ul class="notes draft-notes">
                <draft-note :draft="draft" :line="line.right" :autosave-key="autosaveKey" />
              </ul>
            </article>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>
