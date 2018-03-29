<script>
import { mapState, mapGetters, mapActions } from 'vuex';
import noteForm from '../../notes/components/note_form.vue';
import * as utils from '../store/utils';

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
    ...mapActions(['cancelCommentForm', 'saveNote', 'fetchNotes']),
    handleCancelCommentForm() {
      const { diffLines, line, position } = this;

      this.cancelCommentForm({
        linePosition: position,
        lineCode: line.lineCode,
        diffLines,
        formId: line.id,
      });
    },
    handleSaveNote(note) {
      const postData = utils.getNoteFormData({
        note,
        noteableData: this.noteableData,
        noteableType: this.noteableType,
        noteTargetLine: this.noteTargetLine,
        diffViewType: this.diffViewType,
        diffFile: this.diffFile,
        linePosition: this.position,
      });

      // FIXME: @fatihacet -- This should be fixed, no need to fetchNotes again
      this.saveNote(postData).then(() => {
        const endpoint = this.getNotesDataByProp('discussionsPath');

        this.fetchNotes(endpoint).then(() => {
          this.handleCancelCommentForm();
        });
      });
    },
  },
};
</script>

<template>
  <div class="content discussion-form js-discussion-note-form discussion-form-container">
    <note-form
      :is-editing="true"
      save-button-title="Comment"
      class="diff-comment-form"
      @cancelForm="handleCancelCommentForm"
      @handleFormUpdate="handleSaveNote"
    />
  </div>
</template>
