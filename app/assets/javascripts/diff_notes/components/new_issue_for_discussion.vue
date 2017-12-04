<script>
  /* global CommentsStore */

  import Vue from 'vue';

  const NewIssueForDiscussion = Vue.extend({
    props: {
      discussionId: {
        type: String,
        required: true,
      },
      newIssuePath: {
        type: String,
        required: false,
      },
    },
    data() {
      return {
        discussions: CommentsStore.state,
      };
    },
    computed: {
      discussion() {
        return this.discussions[this.discussionId];
      },
      showButton() {
        if (this.discussion) return !this.discussion.isResolved();
        return false;
      },
    },
  });

  Vue.component('new-issue-for-discussion-btn', NewIssueForDiscussion);
</script>

<template>
  <div
    class="btn-group"
    role="group"
    v-if="showButton"
  >
    <a
      :href="newIssuePath"
      title="Resolve this discussion in a new issue"
      aria-label="Resolve this discussion in a new issue"
      data-container-"body"
      class="new-issue-for-discussion btn btn-default discussion-create-issue-btn has-tooltip"
    >
      <icon name="mr_issue" />
    </a>
  </div>
</template>
