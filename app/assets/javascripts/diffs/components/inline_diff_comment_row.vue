<script>
import { mapGetters, mapState } from 'vuex';
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
    discussions: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  computed: {
    ...mapState({
      diffLineCommentForms: state => state.diffs.diffLineCommentForms,
    }),
    ...mapGetters('diffs', ['discussionsByLineCode']),
    discussions() {
      return this.discussionsByLineCode[this.line.lineCode] || [];
    },
    className() {
      return this.discussions.length ? '' : 'js-temp-notes-holder';
    },
    hasCommentForm() {
      return this.diffLineCommentForms[this.line.lineCode];
    },
  },
};
</script>

<template>
  <tr
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
          v-if="discussions.length"
          :discussions="discussions"
        />
        <diff-line-note-form
          v-if="hasCommentForm"
          :diff-file-hash="diffFileHash"
          :line="line"
          :note-target-line="line"
        />
      </div>
    </td>
  </tr>
</template>
