import { mapState } from 'pinia';
import { sprintf, s__, __ } from '~/locale';
import { useNotes } from '~/notes/store/legacy_notes';

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
    ...mapState(useNotes, ['isDiscussionResolved']),
    resolvedStatusMessage() {
      let message;
      const discussionResolved = this.isDiscussionResolved(
        'draft' in this ? this.draft.discussion_id : this.discussionId,
      );
      const discussionToBeResolved =
        'draft' in this ? this.draft.resolve_discussion : this.resolveDiscussion;

      if (discussionToBeResolved && discussionResolved && !this.$options.showStaysResolved) {
        return undefined;
      }

      if (discussionToBeResolved) {
        message = discussionResolved
          ? s__('MergeRequests|Thread stays resolved')
          : s__('MergeRequests|Thread will be resolved');
      } else if (discussionResolved) {
        message = s__('MergeRequests|Reopen thread');
      } else if (this.$options.showStaysResolved) {
        message = s__('MergeRequests|Resolve thread');
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
