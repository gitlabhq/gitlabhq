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
    className() {
      return this.line.discussions.length ? '' : 'js-temp-notes-holder';
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
      class="notes_content"
      colspan="3"
    >
      <div class="content">
        <diff-discussions
          v-if="line.discussions.length"
          :discussions="line.discussions"
        />
        <diff-line-note-form
          v-if="diffLineCommentForms[line.lineCode]"
          :diff-file-hash="diffFileHash"
          :line="line"
          :note-target-line="line"
        />
      </div>
    </td>
  </tr>
</template>
