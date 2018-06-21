import $ from 'jquery';
import Autosave from '../../autosave';
import { capitalizeFirstCharacter } from '../../lib/utils/text_utility';

export default {
  methods: {
    initAutoSave(noteable) {
      this.autosave = new Autosave($(this.$refs.noteForm.$refs.textarea), [
        'Note',
        capitalizeFirstCharacter(noteable.noteable_type),
        noteable.id,
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
