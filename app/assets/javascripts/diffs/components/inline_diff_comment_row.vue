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
    diffFile: {
      type: Object,
      required: true,
    },
    diffLines: {
      type: Array,
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
    isDiscussionExpanded() {
      if (!this.discussions.length) {
        return false;
      }

      return this.discussions.every(discussion => discussion.expanded);
    },
    hasCommentForm() {
      return this.diffLineCommentForms[this.line.lineCode];
    },
    discussions() {
      return this.discussionsByLineCode[this.line.lineCode] || [];
    },
    shouldRender() {
      return this.isDiscussionExpanded || this.hasCommentForm;
    },
    className() {
      return this.discussions.length ? '' : 'js-temp-notes-holder';
    },
  },
};
</script>

<template>
  <tr
    v-if="shouldRender"
    :class="className"
    class="notes_holder"
  >
    <td
      class="notes_line"
      colspan="2"
    ></td>
    <td class="notes_content">
      <div class="content">
        <diff-discussions
          :discussions="discussions"
        />
        <diff-line-note-form
          v-if="diffLineCommentForms[line.lineCode]"
          :diff-file="diffFile"
          :diff-lines="diffLines"
          :line="line"
          :note-target-line="diffLines[lineIndex]"
        />
      </div>
    </td>
  </tr>
</template>
