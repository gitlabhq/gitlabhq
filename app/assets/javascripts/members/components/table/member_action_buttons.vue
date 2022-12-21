<script>
import { MEMBER_TYPES, EE_ACTION_BUTTONS } from 'ee_else_ce/members/constants';
import AccessRequestActionButtons from '../action_buttons/access_request_action_buttons.vue';
import GroupActionButtons from '../action_buttons/group_action_buttons.vue';
import InviteActionButtons from '../action_buttons/invite_action_buttons.vue';
import UserActionButtons from '../action_buttons/user_action_buttons.vue';

export default {
  name: 'MemberActionButtons',
  components: {
    UserActionButtons,
    GroupActionButtons,
    InviteActionButtons,
    AccessRequestActionButtons,
    BannedActionButtons: () =>
      import('ee_component/members/components/action_buttons/banned_action_buttons.vue'),
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
    memberType: {
      type: String,
      required: true,
    },
    permissions: {
      type: Object,
      required: true,
    },
    isCurrentUser: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    actionButtonComponent() {
      const dictionary = {
        [MEMBER_TYPES.user]: 'user-action-buttons',
        [MEMBER_TYPES.group]: 'group-action-buttons',
        [MEMBER_TYPES.invite]: 'invite-action-buttons',
        [MEMBER_TYPES.accessRequest]: 'access-request-action-buttons',
        ...EE_ACTION_BUTTONS,
      };

      return dictionary[this.memberType];
    },
  },
};
</script>

<template>
  <component
    :is="actionButtonComponent"
    v-if="actionButtonComponent"
    :member="member"
    :permissions="permissions"
    :is-current-user="isCurrentUser"
  />
</template>
