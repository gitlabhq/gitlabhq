import Autosave from '../../autosave';

export default {
  methods: {
    initAutoSave() {
      this.autosave = new Autosave($(this.$refs.noteForm.$refs.textarea), ['Note', 'Issue', this.note.id], 'issue');
    },
    resetAutoSave() {
      this.autosave.reset();
    },
    setAutoSave() {
      this.autosave.save();
    },
  },
};
