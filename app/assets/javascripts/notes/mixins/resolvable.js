export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  computed: {
    discussionResolved() {
      return this.note.notes.reduce((state, note) => state && note.resolved && !note.system, true);
    },
    resolveButtonTitle() {
      return this.discussionResolved ? 'Unresolve discussion' : 'Resolve discussion';
    },
  },
};
