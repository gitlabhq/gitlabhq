<script>
  import jumpToDiscussionBtn from './jump_to_discussion.vue';
  import statusSuccessSvg from '../icons/status_success.svg';

  export default {
    mixins: [DiscussionMixins],
    components: {
      jumpToDiscussionBtn,
    },
    props: {
      loggedOut: {
        type: Boolean,
        required: true,
      },
    },
    data() {
      return {
        discussions: CommentsStore.state
      };
    },
    computed: {
      allResolved() {
        return this.resolvedDiscussionCount === this.discussionCount;
      },
      resolvedCountText() {
        return this.discussionCount === 1 ? 'discussion' : 'discussions';
      },
    },
    created() {
      this.statusSuccessSvg = statusSuccessSvg;
    }
  };
</script>

<template>
  <div class="line-resolve-all-container prepend-top-10">
    <div class="line-resolve-all"
      v-if="discussionCount > 0"
      :class="{ 'has-next-btn': !loggedOut && !allResolved }">
      <span class="line-resolve-btn is-disabled"
        :class="{ 'is-active': allResolved }"
        v-html="statusSuccessSvg">
      </span>
      <span class="line-resolve-text">
        {{ resolvedDiscussionCount }}/{{ discussionCount }} {{ resolvedCountText }} resolved
      </span>
    </div>
    <jump-to-discussion-btn />
  </div>
</template>
