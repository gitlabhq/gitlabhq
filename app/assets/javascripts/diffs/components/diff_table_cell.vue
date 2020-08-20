<script>
import { mapGetters, mapActions } from 'vuex';
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
import { getParameterByName, parseBoolean } from '~/lib/utils/common_utils';
import DiffGutterAvatars from './diff_gutter_avatars.vue';
import { __ } from '~/locale';
import {
  CONTEXT_LINE_TYPE,
  LINE_POSITION_RIGHT,
  EMPTY_CELL_TYPE,
  OLD_NO_NEW_LINE_TYPE,
  OLD_LINE_TYPE,
  NEW_NO_NEW_LINE_TYPE,
  LINE_HOVER_CLASS_NAME,
} from '../constants';

export default {
  components: {
    DiffGutterAvatars,
    GlIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    line: {
      type: Object,
      required: true,
    },
    fileHash: {
      type: String,
      required: true,
    },
    isHighlighted: {
      type: Boolean,
      required: true,
    },
    showCommentButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    linePosition: {
      type: String,
      required: false,
      default: '',
    },
    lineType: {
      type: String,
      required: false,
      default: '',
    },
    isBottom: {
      type: Boolean,
      required: false,
      default: false,
    },
    isHover: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isCommentButtonRendered: false,
    };
  },
  computed: {
    ...mapGetters(['isLoggedIn']),
    lineCode() {
      return (
        this.line.line_code ||
        (this.line.left && this.line.left.line_code) ||
        (this.line.right && this.line.right.line_code)
      );
    },
    lineHref() {
      return `#${this.line.line_code || ''}`;
    },
    shouldShowCommentButton() {
      return this.isHover && !this.isContextLine && !this.isMetaLine && !this.hasDiscussions;
    },
    hasDiscussions() {
      return this.line.discussions && this.line.discussions.length > 0;
    },
    shouldShowAvatarsOnGutter() {
      if (!this.line.type && this.linePosition === LINE_POSITION_RIGHT) {
        return false;
      }
      return this.showCommentButton && this.hasDiscussions;
    },
    shouldRenderCommentButton() {
      if (!this.isCommentButtonRendered) {
        return false;
      }

      if (this.isLoggedIn && this.showCommentButton) {
        const isDiffHead = parseBoolean(getParameterByName('diff_head'));
        return !isDiffHead || gon.features?.mergeRefHeadComments;
      }

      return false;
    },
    isContextLine() {
      return this.line.type === CONTEXT_LINE_TYPE;
    },
    isMetaLine() {
      const { type } = this.line;

      return (
        type === OLD_NO_NEW_LINE_TYPE || type === NEW_NO_NEW_LINE_TYPE || type === EMPTY_CELL_TYPE
      );
    },
    classNameMap() {
      const { type } = this.line;

      return [
        type,
        {
          hll: this.isHighlighted,
          [LINE_HOVER_CLASS_NAME]:
            this.isLoggedIn && this.isHover && !this.isContextLine && !this.isMetaLine,
        },
      ];
    },
    lineNumber() {
      return this.lineType === OLD_LINE_TYPE ? this.line.old_line : this.line.new_line;
    },
    addCommentTooltip() {
      const brokenSymlinks = this.line.commentsDisabled;
      let tooltip = __('Add a comment to this line');

      if (brokenSymlinks) {
        if (brokenSymlinks.wasSymbolic || brokenSymlinks.isSymbolic) {
          tooltip = __(
            'Commenting on symbolic links that replace or are replaced by files is currently not supported.',
          );
        } else if (brokenSymlinks.wasReal || brokenSymlinks.isReal) {
          tooltip = __(
            'Commenting on files that replace or are replaced by symbolic links is currently not supported.',
          );
        }
      }

      return tooltip;
    },
  },
  mounted() {
    this.unwatchShouldShowCommentButton = this.$watch('shouldShowCommentButton', newVal => {
      if (newVal) {
        this.isCommentButtonRendered = true;
        this.unwatchShouldShowCommentButton();
      }
    });
  },
  beforeDestroy() {
    this.unwatchShouldShowCommentButton();
  },
  methods: {
    ...mapActions('diffs', ['showCommentForm', 'setHighlightedRow', 'toggleLineDiscussions']),
    handleCommentButton() {
      this.showCommentForm({ lineCode: this.line.line_code, fileHash: this.fileHash });
    },
  },
};
</script>

<template>
  <td ref="td" :class="classNameMap">
    <span
      ref="addNoteTooltip"
      v-gl-tooltip
      class="add-diff-note tooltip-wrapper"
      :title="addCommentTooltip"
    >
      <button
        v-if="shouldRenderCommentButton"
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
      v-if="lineNumber"
      ref="lineNumberRef"
      :data-linenumber="lineNumber"
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
</template>
