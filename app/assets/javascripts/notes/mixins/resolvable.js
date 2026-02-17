import { createAlert } from '~/alert';
import { __ } from '~/locale';

export default {
  computed: {
    discussionResolved() {
      if (this.discussion) {
        return Boolean(this.discussion.resolved);
      }

      return this.note.resolved;
    },
    resolveButtonTitle() {
      return this.discussionResolved ? __('Reopen thread') : __('Resolve thread');
    },
  },
  methods: {
    resolveHandler(resolvedState = false) {
      if (this.note && this.note.isDraft) {
        return this.$emit('toggleResolveStatus');
      }

      this.isResolving = true;
      const isResolved = this.discussionResolved || resolvedState;
      const discussion = this.resolveAsThread;
      let endpoint =
        discussion && this.discussion ? this.discussion.resolve_path : `${this.note.path}/resolve`;

      if (this.discussionResolvePath) {
        endpoint = this.discussionResolvePath;
      }

      return this.toggleResolveNote({
        endpoint,
        isResolved,
        discussion,
        discussionId: this.discussion?.id,
      })
        .then(() => {
          this.isResolving = false;
        })
        .catch((error) => {
          this.isResolving = false;

          const msg = __('Something went wrong while resolving this discussion. Please try again.');
          createAlert({
            message: msg,
            error,
            captureError: true,
            parent: this.$el,
          });
        });
    },
  },
};
