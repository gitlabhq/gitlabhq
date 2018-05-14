import $ from 'jquery';
import Autosave from '../../autosave';
import { capitalizeFirstCharacter } from '../../lib/utils/text_utility';

export default {
  methods: {
    initAutoSave(noteableType) {
      this.autosave = new Autosave($(this.$refs.noteForm.$refs.textarea), [
        'Note',
        capitalizeFirstCharacter(noteableType),
        this.note.id,
      ]);
    },
    resetAutoSave() {
      this.autosave.reset();
    },
    setAutoSave() {
      this.autosave.save();
    },
  },
};
