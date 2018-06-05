<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import noteForm from '../../notes/components/note_form.vue';
import { getNoteFormData } from '../store/utils';

export default {
  components: {
    noteForm,
  },
  props: {
    diffFile: {
      type: Object,
      required: true,
    },
    diffLines: {
      type: Array,
      required: true,
    },
    line: {
      type: Object,
      required: true,
    },
    position: {
      type: String,
      required: false,
      default: '',
    },
    noteTargetLine: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapState({
      noteableData: state => state.notes.noteableData,
      diffViewType: state => state.diffs.diffViewType,
    }),
    ...mapGetters(['noteableType', 'getNotesDataByProp']),
  },
  methods: {
    ...mapActions(['cancelCommentForm', 'saveNote', 'fetchDiscussions']),
    handleCancelCommentForm() {
      this.cancelCommentForm({
        lineCode: this.line.lineCode,
      });
    },
    handleSaveNote(note) {
      const postData = getNoteFormData({
        note,
        noteableData: this.noteableData,
        noteableType: this.noteableType,
        noteTargetLine: this.noteTargetLine,
        diffViewType: this.diffViewType,
        diffFile: this.diffFile,
        linePosition: this.position,
      });

      this.saveNote(postData)
        .then(() => {
          const endpoint = this.getNotesDataByProp('discussionsPath');

          this.fetchDiscussions(endpoint)
            .then(() => {
              this.handleCancelCommentForm();
            })
            .catch(() => {});
        })
        .catch(() => {});
    },
  },
};
</script>

<template>
  <div
    class="content discussion-form discussion-form-container discussion-notes"
  >
    <note-form
      :is-editing="true"
      save-button-title="Comment"
      class="diff-comment-form"
      :line-code="line.lineCode"
      @cancelForm="handleCancelCommentForm"
      @handleFormUpdate="handleSaveNote"
    />
  </div>
</template>
