import * as constants from '../constants';

export default {
  computed: {
    noteableType() {
      const note = this.discussion ? this.discussion.notes[0] : this.note;
      return constants.NOTEABLE_TYPE_MAPPING[note.noteable_type];
    },
  },
};
