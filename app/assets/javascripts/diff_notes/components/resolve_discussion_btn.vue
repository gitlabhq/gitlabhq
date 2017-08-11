<script>
  /* global ResolveService */
  /* global CommentsStore */

  export default {
    props: {
      discussionId: {
        type: String,
        required: true,
      },
      mergeRequestId: {
        type: Number,
        required: true,
      },
      canResolve: {
        type: Boolean,
        required: true,
      },
    },
    computed: {
      discussion() {
        return CommentsStore.state[this.discussionId];
      },
      showButton() {
        if (this.discussion) {
          return this.discussion.isResolvable();
        }

        return false;
      },
      isDiscussionResolved() {
        if (this.discussion) {
          return this.discussion.isResolved();
        }

        return false;
      },
      loading() {
        if (this.discussion) {
          return this.discussion.loading;
        }

        return false;
      },
    },
    methods: {
      resolve() {
        ResolveService.toggleResolveForDiscussion(this.mergeRequestId, this.discussionId);
      },
    },
    created() {
      CommentsStore.createDiscussion(this.discussionId, this.canResolve);
    },
  };
</script>

<template>
  <div class="btn-group"
    role="group"
    v-if="showButton">
    <button class="btn btn-default"
      type="button"
      @click="resolve"
      :disabled="loading">
      <i class="fa fa-spinner fa-spin"
        v-if="loading">
      </i>
      <template v-if="isDiscussionResolved">
        Unresolve discussion
      </template>
      <template v-else>
        Resolve discussion
      </template>
    </button>
  </div>
</template>
