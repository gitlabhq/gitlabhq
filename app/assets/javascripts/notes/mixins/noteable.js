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
      return constants.NOTEABLE_TYPE_MAPPING[this.note.noteable_type];
    },
  },
};
