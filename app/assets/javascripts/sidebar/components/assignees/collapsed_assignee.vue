<script>
import { GlButton } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import AssigneeAvatar from './assignee_avatar.vue';
import UserNameWithStatus from './user_name_with_status.vue';

export default {
  components: {
    GlButton,
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
      default: TYPE_ISSUE,
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
  <gl-button variant="link" class="!gl-bg-transparent">
    <assignee-avatar :user="user" :img-size="24" :issuable-type="issuableType" />
    <user-name-with-status
      :name="user.name"
      :availability="availability"
      container-classes="author"
    />
  </gl-button>
</template>
