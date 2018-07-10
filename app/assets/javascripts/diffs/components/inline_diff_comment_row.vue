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
    discussions() {
      return this.discussionsByLineCode[this.line.lineCode] || [];
    },
    className() {
      return this.discussions.length ? '' : 'js-temp-notes-holder';
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
