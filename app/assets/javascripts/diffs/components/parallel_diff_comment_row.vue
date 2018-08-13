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
  },
  computed: {
    ...mapState({
      diffLineCommentForms: state => state.diffs.diffLineCommentForms,
    }),
    leftLineCode() {
      return this.line.left && this.line.left.lineCode;
    },
    rightLineCode() {
      return this.line.right && this.line.right.lineCode;
    },
    hasExpandedDiscussionOnLeft() {
      return this.line.left && this.line.left.discussions
        ? this.line.left.discussions.every(discussion => discussion.expanded)
        : false;
    },
    hasExpandedDiscussionOnRight() {
      return this.line.right && this.line.right.discussions
        ? this.line.right.discussions.every(discussion => discussion.expanded)
        : false;
    },
    hasAnyExpandedDiscussion() {
      return this.hasExpandedDiscussionOnLeft || this.hasExpandedDiscussionOnRight;
    },
    shouldRenderDiscussionsOnLeft() {
      return this.line.left && this.line.left.discussions && this.hasExpandedDiscussionOnLeft;
    },
    shouldRenderDiscussionsOnRight() {
      return (
        this.line.right &&
        this.line.right.discussions &&
        this.hasExpandedDiscussionOnRight &&
        this.line.right.type
      );
    },
    showRightSideCommentForm() {
      return this.line.right.type && this.diffLineCommentForms[this.rightLineCode];
    },
    className() {
      return (this.left && this.line.left.discussions.length > 0) ||
        (this.right && this.line.right.discussions.length > 0)
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
          v-if="line.left.discussions.length"
          :discussions="line.left.discussions"
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
          v-if="line.right.discussions.length"
          :discussions="line.right.discussions"
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
