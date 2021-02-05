import $ from 'jquery';
import { s__ } from '~/locale';
import Autosave from '../../autosave';
import { capitalizeFirstCharacter } from '../../lib/utils/text_utility';

export default {
  methods: {
    initAutoSave(noteable, extraKeys = []) {
      let keys = [
        s__('Autosave|Note'),
        capitalizeFirstCharacter(noteable.noteable_type || noteable.noteableType),
        noteable.id,
      ];

      if (extraKeys) {
        keys = keys.concat(extraKeys);
      }

      this.autosave = new Autosave($(this.$refs.noteForm.$refs.textarea), keys);
    },
    resetAutoSave() {
      this.autosave.reset();
    },
    setAutoSave() {
      this.autosave.save();
    },
    disposeAutoSave() {
      this.autosave.dispose();
    },
  },
};
