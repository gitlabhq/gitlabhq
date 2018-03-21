import Flash from '~/flash';
import { __ } from '~/locale';

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

      if (notes) {
        // Decide resolved state using store. Only valid for discussions.
        return notes.every(note => note.resolved && !note.system);
      }

      return resolved;
    },
    resolveButtonTitle() {
      if (this.updatedNoteBody) {
        if (this.discussionResolved) {
          return __('Comment and unresolve discussion');
        }

        return __('Comment and resolve discussion');
      }
      return this.discussionResolved
        ? __('Unresolve discussion')
        : __('Resolve discussion');
    },
  },
  methods: {
    resolveHandler(resolvedState = false) {
      this.isResolving = true;
      const isResolved = this.discussionResolved || resolvedState;
      const discussion = this.resolveAsThread;
      let endpoint = `${this.note.path}/resolve`;

      if (discussion) {
        endpoint = this.note.resolve_path;
      }

      this.toggleResolveNote({ endpoint, isResolved, discussion })
        .then(() => {
          this.isResolving = false;
        })
        .catch(() => {
          this.isResolving = false;
          const msg = __(
            'Something went wrong while resolving this discussion. Please try again.',
          );
          Flash(msg, 'alert', this.$el);
        });
    },
  },
};
