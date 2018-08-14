<script>
import { mapState } from 'vuex';
import diffDiscussions from './diff_discussions.vue';
import diffLineNoteForm from './diff_line_note_form.vue';

export default {
  components: {
    diffDiscussions,
    diffLineNoteForm,
  },
  props: {
    line: {
      type: Object,
      required: true,
    },
    diffFileHash: {
      type: String,
      required: true,
    },
    lineIndex: {
      type: Number,
      required: true,
    },
    leftDiscussions: {
      type: Array,
      required: false,
      default: () => [],
    },
    rightDiscussions: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    ...mapState({
      diffLineCommentForms: state => state.diffs.diffLineCommentForms,
    }),
    leftLineCode() {
      return this.line.left.lineCode;
    },
    rightLineCode() {
      return this.line.right.lineCode;
    },
    hasExpandedDiscussionOnLeft() {
      const discussions = this.leftDiscussions;

      return discussions ? discussions.every(discussion => discussion.expanded) : false;
    },
    hasExpandedDiscussionOnRight() {
      const discussions = this.rightDiscussions;

      return discussions ? discussions.every(discussion => discussion.expanded) : false;
    },
    hasAnyExpandedDiscussion() {
      return this.hasExpandedDiscussionOnLeft || this.hasExpandedDiscussionOnRight;
    },
    shouldRenderDiscussionsOnLeft() {
      return this.leftDiscussions && this.hasExpandedDiscussionOnLeft;
    },
    shouldRenderDiscussionsOnRight() {
      return this.rightDiscussions && this.hasExpandedDiscussionOnRight && this.line.right.type;
    },
    showRightSideCommentForm() {
      return this.line.right.type && this.diffLineCommentForms[this.rightLineCode];
    },
    className() {
      return this.leftDiscussions.length > 0 || this.rightDiscussions.length > 0
        ? ''
        : 'js-temp-notes-holder';
    },
  },
};
</script>

<template>
  <tr
    :class="className"
    class="notes_holder"
  >
    <td class="notes_line old"></td>
    <td class="notes_content parallel old">
      <div
        v-if="shouldRenderDiscussionsOnLeft"
        class="content"
      >
        <diff-discussions
          v-if="leftDiscussions.length"
          :discussions="leftDiscussions"
        />
      </div>
      <diff-line-note-form
        v-if="diffLineCommentForms[leftLineCode]"
        :diff-file-hash="diffFileHash"
        :line="line.left"
        :note-target-line="line.left"
        position="left"
      />
    </td>
    <td class="notes_line new"></td>
    <td class="notes_content parallel new">
      <div
        v-if="shouldRenderDiscussionsOnRight"
        class="content"
      >
        <diff-discussions
          v-if="rightDiscussions.length"
          :discussions="rightDiscussions"
        />
      </div>
      <diff-line-note-form
        v-if="showRightSideCommentForm"
        :diff-file-hash="diffFileHash"
        :line="line.right"
        :note-target-line="line.right"
        position="right"
      />
    </td>
  </tr>
</template>
