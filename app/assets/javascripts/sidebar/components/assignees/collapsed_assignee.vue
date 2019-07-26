<script>
import AssigneeAvatar from './assignee_avatar.vue';

export default {
  components: {
    AssigneeAvatar,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    issuableType: {
      type: String,
      require: true,
      default: 'issue',
    },
  },
};
</script>

<template>
  <button type="button" class="btn-link">
    <assignee-avatar :user="user" :img-size="24" :issuable-type="issuableType" />
    <span class="author"> {{ user.name }} </span>
  </button>
</template>
