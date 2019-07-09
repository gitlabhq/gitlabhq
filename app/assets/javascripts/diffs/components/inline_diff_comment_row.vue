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
  },
  computed: {
    className() {
      return this.line.discussions.length ? '' : 'js-temp-notes-holder';
    },
    shouldRender() {
      if (this.line.hasForm) return true;

      if (!this.line.discussions || !this.line.discussions.length) {
        return false;
      }
      return this.line.discussionsExpanded;
    },
  },
  methods: {
    ...mapActions('diffs', ['showCommentForm']),
  },
};
</script>

<template>
  <tr v-if="shouldRender" :class="className" class="notes_holder">
    <td class="notes-content" colspan="3">
      <div class="content">
        <diff-discussions
          v-if="line.discussions.length"
          :line="line"
          :discussions="line.discussions"
          :help-page-path="helpPagePath"
        />
        <diff-discussion-reply
          v-if="!hasDraft"
          :has-form="line.hasForm"
          :render-reply-placeholder="Boolean(line.discussions.length)"
          @showNewDiscussionForm="
            showCommentForm({ lineCode: line.line_code, fileHash: diffFileHash })
          "
        >
          <template #form>
            <diff-line-note-form
              :diff-file-hash="diffFileHash"
              :line="line"
              :note-target-line="line"
              :help-page-path="helpPagePath"
            />
          </template>
        </diff-discussion-reply>
      </div>
    </td>
  </tr>
</template>
