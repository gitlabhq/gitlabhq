<script>
import { mapActions } from 'vuex';
import DiffDiscussions from './diff_discussions.vue';
import DiffLineNoteForm from './diff_line_note_form.vue';
import DiffDiscussionReply from './diff_discussion_reply.vue';

export default {
  components: {
    DiffDiscussions,
    DiffLineNoteForm,
    DiffDiscussionReply,
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
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    hasDraftLeft: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasDraftRight: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    hasExpandedDiscussionOnLeft() {
      return this.line.left && this.line.left.discussions.length
        ? this.line.left.discussionsExpanded
        : false;
    },
    hasExpandedDiscussionOnRight() {
      return this.line.right && this.line.right.discussions.length
        ? this.line.right.discussionsExpanded
        : false;
    },
    hasAnyExpandedDiscussion() {
      return this.hasExpandedDiscussionOnLeft || this.hasExpandedDiscussionOnRight;
    },
    shouldRenderDiscussionsOnLeft() {
      return (
        this.line.left &&
        this.line.left.discussions &&
        this.line.left.discussions.length &&
        this.hasExpandedDiscussionOnLeft
      );
    },
    shouldRenderDiscussionsOnRight() {
      return (
        this.line.right &&
        this.line.right.discussions &&
        this.line.right.discussions.length &&
        this.hasExpandedDiscussionOnRight &&
        this.line.right.type
      );
    },
    showRightSideCommentForm() {
      return this.line.right && this.line.right.type && this.line.right.hasForm;
    },
    showLeftSideCommentForm() {
      return this.line.left && this.line.left.hasForm;
    },
    className() {
      return (this.left && this.line.left.discussions.length > 0) ||
        (this.right && this.line.right.discussions.length > 0)
        ? ''
        : 'js-temp-notes-holder';
    },
    shouldRender() {
      const { line } = this;
      const hasDiscussion =
        (line.left && line.left.discussions && line.left.discussions.length) ||
        (line.right && line.right.discussions && line.right.discussions.length);

      if (
        hasDiscussion &&
        (this.hasExpandedDiscussionOnLeft || this.hasExpandedDiscussionOnRight)
      ) {
        return true;
      }

      const hasCommentFormOnLeft = line.left && line.left.hasForm;
      const hasCommentFormOnRight = line.right && line.right.hasForm;

      return hasCommentFormOnLeft || hasCommentFormOnRight;
    },
    shouldRenderReplyPlaceholderOnLeft() {
      return Boolean(
        this.line.left && this.line.left.discussions && this.line.left.discussions.length,
      );
    },
    shouldRenderReplyPlaceholderOnRight() {
      return Boolean(
        this.line.right && this.line.right.discussions && this.line.right.discussions.length,
      );
    },
  },
  methods: {
    ...mapActions('diffs', ['showCommentForm']),
    showNewDiscussionForm() {
      this.showCommentForm({ lineCode: this.line.line_code, fileHash: this.diffFileHash });
    },
  },
};
</script>

<template>
  <tr v-if="shouldRender" :class="className" class="notes_holder">
    <td class="notes-content parallel old" colspan="2">
      <div v-if="shouldRenderDiscussionsOnLeft" class="content">
        <diff-discussions
          :discussions="line.left.discussions"
          :line="line.left"
          :help-page-path="helpPagePath"
        />
      </div>
      <diff-discussion-reply
        v-if="!hasDraftLeft"
        :has-form="showLeftSideCommentForm"
        :render-reply-placeholder="shouldRenderReplyPlaceholderOnLeft"
        @showNewDiscussionForm="showNewDiscussionForm"
      >
        <template #form>
          <diff-line-note-form
            :diff-file-hash="diffFileHash"
            :line="line.left"
            :note-target-line="line.left"
            :help-page-path="helpPagePath"
            line-position="left"
          />
        </template>
      </diff-discussion-reply>
    </td>
    <td class="notes-content parallel new" colspan="2">
      <div v-if="shouldRenderDiscussionsOnRight" class="content">
        <diff-discussions
          :discussions="line.right.discussions"
          :line="line.right"
          :help-page-path="helpPagePath"
        />
      </div>
      <diff-discussion-reply
        v-if="!hasDraftRight"
        :has-form="showRightSideCommentForm"
        :render-reply-placeholder="shouldRenderReplyPlaceholderOnRight"
        @showNewDiscussionForm="showNewDiscussionForm"
      >
        <template #form>
          <diff-line-note-form
            :diff-file-hash="diffFileHash"
            :line="line.right"
            :note-target-line="line.right"
            line-position="right"
          />
        </template>
      </diff-discussion-reply>
    </td>
  </tr>
</template>
