<script>
import { mapState, mapGetters } from 'vuex';
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
    ...mapGetters(['discussionsByLineCode']),
    leftLineCode() {
      return this.line.left.lineCode;
    },
    rightLineCode() {
      return this.line.right.lineCode;
    },
    hasDiscussion() {
      const discussions = this.discussionsByLineCode;

      return discussions[this.leftLineCode] || discussions[this.rightLineCode];
    },
    hasExpandedDiscussionOnLeft() {
      const discussions = this.discussionsByLineCode[this.leftLineCode];

      return discussions ? discussions.every(discussion => discussion.expanded) : false;
    },
    hasExpandedDiscussionOnRight() {
      const discussions = this.discussionsByLineCode[this.rightLineCode];

      return discussions ? discussions.every(discussion => discussion.expanded) : false;
    },
    hasAnyExpandedDiscussion() {
      return this.hasExpandedDiscussionOnLeft || this.hasExpandedDiscussionOnRight;
    },
    shouldRenderDiscussionsOnLeft() {
      return this.discussionsByLineCode[this.leftLineCode] && this.hasExpandedDiscussionOnLeft;
    },
    shouldRenderDiscussionsOnRight() {
      return (
        this.discussionsByLineCode[this.rightLineCode] &&
        this.hasExpandedDiscussionOnRight &&
        this.line.right.type
      );
    },
    className() {
      return this.hasDiscussion ? '' : 'js-temp-notes-holder';
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
          v-if="discussionsByLineCode[leftLineCode].length"
          :discussions="discussionsByLineCode[leftLineCode]"
        />
      </div>
      <diff-line-note-form
        v-if="diffLineCommentForms[leftLineCode] &&
        diffLineCommentForms[leftLineCode]"
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
          v-if="discussionsByLineCode[rightLineCode].length"
          :discussions="discussionsByLineCode[rightLineCode]"
        />
      </div>
      <diff-line-note-form
        v-if="diffLineCommentForms[rightLineCode] &&
        diffLineCommentForms[rightLineCode] && line.right.type"
        :diff-file-hash="diffFileHash"
        :line="line.right"
        :note-target-line="line.right"
        position="right"
      />
    </td>
  </tr>
</template>
