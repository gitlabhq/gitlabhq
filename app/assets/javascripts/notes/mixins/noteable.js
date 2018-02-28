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
      switch (this.note.noteable_type) {
        case 'MergeRequest':
          return constants.MERGE_REQUEST_NOTEABLE_TYPE;
        case 'Issue':
          return constants.ISSUE_NOTEABLE_TYPE;
        default:
          return '';
      }
    },
  },
};
