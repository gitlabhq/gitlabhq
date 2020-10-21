<script>
// NOTE! For the first iteration, we are simply copying the implementation of Assignees
// It will soon be overhauled in Issue https://gitlab.com/gitlab-org/gitlab/-/issues/233736
import ReviewerAvatar from './reviewer_avatar.vue';

export default {
  components: {
    ReviewerAvatar,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <button type="button" class="btn-link">
    <reviewer-avatar :user="user" :img-size="24" />
    <span class="author"> {{ user.name }} </span>
  </button>
</template>
