<script>
import ReplyPlaceholder from './discussion_reply_placeholder.vue';
import ResolveDiscussionButton from './discussion_resolve_button.vue';
import ResolveWithIssueButton from './discussion_resolve_with_issue_button.vue';
import JumpToNextDiscussionButton from './discussion_jump_to_next_button.vue';

export default {
  name: 'DiscussionActions',
  components: {
    ReplyPlaceholder,
    ResolveDiscussionButton,
    ResolveWithIssueButton,
    JumpToNextDiscussionButton,
  },
  props: {
    discussion: {
      type: Object,
      required: true,
    },
    isResolving: {
      type: Boolean,
      required: true,
    },
    resolveButtonTitle: {
      type: String,
      required: true,
    },
    resolveWithIssuePath: {
      type: String,
      required: false,
      default: '',
    },
    shouldShowJumpToNextDiscussion: {
      type: Boolean,
      required: true,
    },
  },
};
</script>

<template>
  <div class="discussion-with-resolve-btn clearfix">
    <reply-placeholder class="qa-discussion-reply" @onClick="$emit('showReplyForm')" />

    <div class="btn-group discussion-actions" role="group">
      <resolve-discussion-button
        v-if="discussion.resolvable"
        :is-resolving="isResolving"
        :button-title="resolveButtonTitle"
        @onClick="$emit('resolve')"
      />
      <resolve-with-issue-button
        v-if="discussion.resolvable && resolveWithIssuePath"
        :url="resolveWithIssuePath"
      />
    </div>

    <div
      v-if="discussion.resolvable && shouldShowJumpToNextDiscussion"
      class="btn-group discussion-actions ml-sm-2"
    >
      <jump-to-next-discussion-button @onClick="$emit('jumpToNextDiscussion')" />
    </div>
  </div>
</template>
