<script>
import ResolveDiscussionButton from '~/notes/components/discussion_resolve_button.vue';
import DiscussionReplyPlaceholder from '~/notes/components/discussion_reply_placeholder.vue';
import { __ } from '~/locale';
import discussionToggleResolveMutation from '../graphql/discussion_toggle_resolve.mutation.graphql';

export default {
  name: 'DiscussionActions',
  components: {
    DiscussionReplyPlaceholder,
    ResolveDiscussionButton,
  },
  props: {
    discussionId: {
      type: String,
      required: true,
    },
    showResolveButton: {
      type: Boolean,
      required: false,
      default: false,
    },
    isResolved: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    toggleResolveBtnLabel() {
      return this.isResolved ? __('Reopen thread') : __('Resolve thread');
    },
  },
  methods: {
    async onToggleResolve() {
      this.loading = true;
      try {
        await this.$apollo.mutate({
          mutation: discussionToggleResolveMutation,
          variables: {
            id: this.discussionId,
            resolve: !this.isResolved,
          },
        });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div class="discussion-with-resolve-btn gl-clearfix">
    <discussion-reply-placeholder @focus="$emit('showReplyForm')" />

    <div v-if="showResolveButton" class="btn-group discussion-actions" role="group">
      <div class="btn-group">
        <resolve-discussion-button
          :is-resolving="loading"
          :button-title="toggleResolveBtnLabel"
          @onClick="onToggleResolve"
        />
      </div>
    </div>
  </div>
</template>
