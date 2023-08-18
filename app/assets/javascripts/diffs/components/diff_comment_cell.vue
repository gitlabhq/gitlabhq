<script>
// eslint-disable-next-line no-restricted-imports
import { mapActions } from 'vuex';
import DiffDiscussionReply from './diff_discussion_reply.vue';
import DiffDiscussions from './diff_discussions.vue';
import DiffLineNoteForm from './diff_line_note_form.vue';

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
    helpPagePath: {
      type: String,
      required: false,
      default: '',
    },
    hasDraft: {
      type: Boolean,
      required: false,
      default: false,
    },
    lineRange: {
      type: Object,
      required: false,
      default: null,
    },
    linePosition: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    ...mapActions('diffs', ['showCommentForm']),
  },
};
</script>

<template>
  <div class="content">
    <diff-discussions
      v-if="line.renderDiscussion"
      :line="line"
      :discussions="line.discussions"
      :help-page-path="helpPagePath"
    />
    <diff-discussion-reply
      v-if="!hasDraft"
      :has-form="line.hasCommentForm"
      :render-reply-placeholder="Boolean(line.discussions.length)"
      @showNewDiscussionForm="showCommentForm({ lineCode: line.line_code, fileHash: diffFileHash })"
    >
      <template #form>
        <diff-line-note-form
          :diff-file-hash="diffFileHash"
          :line="line"
          :range="lineRange"
          :note-target-line="line"
          :help-page-path="helpPagePath"
          :line-position="linePosition"
        />
      </template>
    </diff-discussion-reply>
  </div>
</template>
