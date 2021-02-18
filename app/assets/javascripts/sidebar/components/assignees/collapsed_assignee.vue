<script>
import AssigneeAvatar from './assignee_avatar.vue';
import UserNameWithStatus from './user_name_with_status.vue';

export default {
  components: {
    AssigneeAvatar,
    UserNameWithStatus,
  },
  props: {
    user: {
      type: Object,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
  },
  computed: {
    availability() {
      return this.user?.availability || '';
    },
  },
};
</script>
<template>
  <button type="button" class="btn-link">
    <assignee-avatar :user="user" :img-size="24" :issuable-type="issuableType" />
    <user-name-with-status
      :name="user.name"
      :availability="availability"
      container-classes="author"
    />
  </button>
</template>
