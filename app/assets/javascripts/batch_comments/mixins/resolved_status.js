import { mapGetters } from 'vuex';
import { sprintf, s__, __ } from '~/locale';

export default {
  props: {
    discussionId: {
      type: String,
      required: false,
      default: null,
    },
    resolveDiscussion: {
      type: Boolean,
      required: false,
      default: false,
    },
    isDraft: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    ...mapGetters(['isDiscussionResolved']),
    resolvedStatusMessage() {
      let message;
      const discussionResolved = this.isDiscussionResolved(
        this.draft ? this.draft.discussion_id : this.discussionId,
      );
      const discussionToBeResolved = this.draft
        ? this.draft.resolve_discussion
        : this.resolveDiscussion;

      if (discussionToBeResolved && discussionResolved && !this.$options.showStaysResolved) {
        return undefined;
      }

      if (discussionToBeResolved) {
        message = discussionResolved
          ? s__('MergeRequests|Thread stays resolved')
          : s__('MergeRequests|Thread will be resolved');
      } else if (discussionResolved) {
        message = s__('MergeRequests|Thread will be unresolved');
      } else if (this.$options.showStaysResolved) {
        message = s__('MergeRequests|Thread stays unresolved');
      }

      return message;
    },
    componentClasses() {
      return this.resolveDiscussion ? 'is-resolving-discussion' : 'is-unresolving-discussion';
    },
    resolveButtonTitle() {
      const escapeParameters = false;

      if (this.isDraft || this.discussionId) return this.resolvedStatusMessage;

      let title = __('Resolve thread');

      if (this.resolvedBy) {
        title = sprintf(
          __('Resolved by %{name}'),
          { name: this.resolvedBy.name },
          escapeParameters,
        );
      }

      return title;
    },
  },
  showStaysResolved: true,
};
