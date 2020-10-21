<script>
import { mapActions, mapGetters, mapState } from 'vuex';
import { GlTooltipDirective, GlIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { CONTEXT_LINE_CLASS_NAME } from '../constants';
import DiffGutterAvatars from './diff_gutter_avatars.vue';
import * as utils from './diff_row_utils';

export default {
  components: {
    DiffGutterAvatars,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  props: {
    fileHash: {
      type: String,
      required: true,
    },
    filePath: {
      type: String,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    isBottom: {
      type: Boolean,
      required: false,
      default: false,
    },
    isCommented: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isHover: false,
    };
  },
  computed: {
    ...mapGetters(['isLoggedIn']),
    ...mapGetters('diffs', ['fileLineCoverage']),
    ...mapState({
      isHighlighted(state) {
        return utils.isHighlighted(state, this.line, this.isCommented);
      },
    }),
    isContextLine() {
      return utils.isContextLine(this.line.type);
    },
    classNameMap() {
      return [
        this.line.type,
        {
          [CONTEXT_LINE_CLASS_NAME]: this.isContextLine,
        },
      ];
    },
    inlineRowId() {
      return this.line.line_code || `${this.fileHash}_${this.line.old_line}_${this.line.new_line}`;
    },
    isMatchLine() {
      return utils.isMatchLine(this.line.type);
    },
    coverageState() {
      return this.fileLineCoverage(this.filePath, this.line.new_line);
    },
    isMetaLine() {
      return utils.isMetaLine(this.line.type);
    },
    classNameMapCell() {
      return utils.classNameMapCell(this.line, this.isHighlighted, this.isLoggedIn, this.isHover);
    },
    addCommentTooltip() {
      return utils.addCommentTooltip(this.line);
    },
    shouldRenderCommentButton() {
      return utils.shouldRenderCommentButton(this.isLoggedIn, true);
    },
    shouldShowCommentButton() {
      return utils.shouldShowCommentButton(
        this.isHover,
        this.isContextLine,
        this.isMetaLine,
        this.hasDiscussions,
      );
    },
    hasDiscussions() {
      return utils.hasDiscussions(this.line);
    },
    lineHref() {
      return utils.lineHref(this.line);
    },
    lineCode() {
      return utils.lineCode(this.line);
    },
    shouldShowAvatarsOnGutter() {
      return this.hasDiscussions;
    },
  },
  mounted() {
    this.scrollToLineIfNeededInline(this.line);
  },
  methods: {
    ...mapActions('diffs', [
      'scrollToLineIfNeededInline',
      'showCommentForm',
      'setHighlightedRow',
      'toggleLineDiscussions',
    ]),
    handleMouseMove(e) {
      // To show the comment icon on the gutter we need to know if we hover the line.
      // Current table structure doesn't allow us to do this with CSS in both of the diff view types
      this.isHover = e.type === 'mouseover';
    },
    handleCommentButton() {
      this.showCommentForm({ lineCode: this.line.line_code, fileHash: this.fileHash });
    },
  },
};
</script>

<template>
  <tr
    v-if="!isMatchLine"
    :id="inlineRowId"
    :class="classNameMap"
    class="line_holder"
    @mouseover="handleMouseMove"
    @mouseout="handleMouseMove"
  >
    <td ref="oldTd" class="diff-line-num old_line" :class="classNameMapCell">
      <span
        v-if="shouldRenderCommentButton"
        ref="addNoteTooltip"
        v-gl-tooltip
        class="add-diff-note tooltip-wrapper"
        :title="addCommentTooltip"
      >
        <button
          v-show="shouldShowCommentButton"
          ref="addDiffNoteButton"
          type="button"
          class="add-diff-note note-button js-add-diff-note-button qa-diff-comment"
          :disabled="line.commentsDisabled"
          @click="handleCommentButton"
        >
          <gl-icon :size="12" name="comment" />
        </button>
      </span>
      <a
        v-if="line.old_line"
        ref="lineNumberRefOld"
        :data-linenumber="line.old_line"
        :href="lineHref"
        @click="setHighlightedRow(lineCode)"
      >
      </a>
      <diff-gutter-avatars
        v-if="shouldShowAvatarsOnGutter"
        :discussions="line.discussions"
        :discussions-expanded="line.discussionsExpanded"
        @toggleLineDiscussions="
          toggleLineDiscussions({ lineCode, fileHash, expanded: !line.discussionsExpanded })
        "
      />
    </td>
    <td ref="newTd" class="diff-line-num new_line qa-new-diff-line" :class="classNameMapCell">
      <a
        v-if="line.new_line"
        ref="lineNumberRefNew"
        :data-linenumber="line.new_line"
        :href="lineHref"
        @click="setHighlightedRow(lineCode)"
      >
      </a>
    </td>
    <td
      v-gl-tooltip.hover
      :title="coverageState.text"
      :class="[line.type, coverageState.class, { hll: isHighlighted }]"
      class="line-coverage"
    ></td>
    <td
      :key="line.line_code"
      v-safe-html="line.rich_text"
      :class="[
        line.type,
        {
          hll: isHighlighted,
        },
      ]"
      class="line_content with-coverage"
    ></td>
  </tr>
</template>
