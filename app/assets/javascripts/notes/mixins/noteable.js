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
          return 'merge_request';
        case 'Issue':
          return 'issue';
        default:
          return '';
      }
    },
  },
};
