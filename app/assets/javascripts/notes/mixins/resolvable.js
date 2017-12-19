/* global Flash */

export default {
  props: {
    note: {
      type: Object,
      required: true,
    },
  },
  computed: {
    discussionResolved() {
      const { notes, resolved } = this.note;

      if (notes) { // Decide resolved state using store. Only valid for discussions.
        return notes.reduce((state, note) => state && note.resolved && !note.system, true);
      }

      return resolved;
    },
    resolveButtonTitle() {
      if (this.updatedNoteBody) {
        if (this.discussionResolved) {
          return 'Comment and unresolve discussion';
        }

        return 'Comment and resolve discussion';
      }
      return this.discussionResolved ? 'Unresolve discussion' : 'Resolve discussion';
    },
  },
  methods: {
    resolveHandler() {
      this.isResolving = true;
      const endpoint = this.note.resolve_path || `${this.note.path}/resolve`;
      const isResolved = this.discussionResolved;
      const discussion = this.resolveAsThread;

      this.toggleResolveNote({ endpoint, isResolved, discussion })
        .then(() => {
          this.isResolving = false;
        })
        .catch(() => {
          const msg = 'Something went wrong while resolving this discussion. Please try again.';
          Flash(msg, 'alert', this.$el);
        });
    },
  },
};
