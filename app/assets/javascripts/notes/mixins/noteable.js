import * as constants from '../constants';

export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  computed: {
    noteableType() {
      let note = this.note;
      if (note.notes) {
        note = note.notes[0];
      }
      return constants.NOTEABLE_TYPE_MAPPING[note.noteable_type];
    },
  },
};
