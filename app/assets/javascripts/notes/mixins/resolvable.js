import Flash from '~/flash';
import { __ } from '~/locale';

export default {
  computed: {
    discussionResolved() {
      if (this.discussion) {
        const { notes, resolved } = this.discussion;

        if (notes) {
          // Decide resolved state using store. Only valid for discussions.
          return notes.filter(note => !note.system).every(note => note.resolved);
        }

        return resolved;
      }

      return this.note.resolved;
    },
    resolveButtonTitle() {
      if (this.updatedNoteBody) {
        if (this.discussionResolved) {
          return __('Comment & unresolve discussion');
        }

        return __('Comment & resolve discussion');
      }

      return this.discussionResolved ? __('Unresolve discussion') : __('Resolve discussion');
    },
  },
  methods: {
    resolveHandler(resolvedState = false) {
      this.isResolving = true;
      const isResolved = this.discussionResolved || resolvedState;
      const discussion = this.resolveAsThread;
      const endpoint = discussion ? this.discussion.resolve_path : `${this.note.path}/resolve`;

      this.toggleResolveNote({ endpoint, isResolved, discussion })
        .then(() => {
          this.isResolving = false;
        })
        .catch(() => {
          this.isResolving = false;

          const msg = __('Something went wrong while resolving this discussion. Please try again.');
          Flash(msg, 'alert', this.$el);
        });
    },
  },
};
