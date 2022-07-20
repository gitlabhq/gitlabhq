<script>
import { kebabCase } from 'lodash';
import GroupAvatar from '../avatars/group_avatar.vue';
import InviteAvatar from '../avatars/invite_avatar.vue';
import UserAvatar from '../avatars/user_avatar.vue';

export default {
  name: 'MemberAvatar',
  components: {
    UserAvatar,
    InviteAvatar,
    GroupAvatar,
    AccessRequestAvatar: UserAvatar,
    BannedAvatar: UserAvatar,
  },
  props: {
    memberType: {
      type: String,
      required: true,
    },
    isCurrentUser: {
      type: Boolean,
      required: true,
    },
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    avatarComponent() {
      // eslint-disable-next-line @gitlab/require-i18n-strings
      return `${kebabCase(this.memberType)}-avatar`;
    },
  },
};
</script>

<template>
  <component :is="avatarComponent" :member="member" :is-current-user="isCurrentUser" />
</template>
