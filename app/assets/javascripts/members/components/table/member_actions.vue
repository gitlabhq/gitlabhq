<script>
import { MEMBERS_TAB_TYPES, ACTION_BUTTONS } from 'ee_else_ce/members/constants';
import AccessRequestActionButtons from '../action_buttons/access_request_action_buttons.vue';
import GroupActionButtons from '../action_buttons/group_action_buttons.vue';
import InviteActionButtons from '../action_buttons/invite_action_buttons.vue';
import UserActionDropdown from '../action_dropdowns/user_action_dropdown.vue';

export default {
  name: 'MemberActions',
  components: {
    UserActionDropdown,
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
        [MEMBERS_TAB_TYPES.user]: 'user-action-dropdown',
        [MEMBERS_TAB_TYPES.group]: 'group-action-buttons',
        [MEMBERS_TAB_TYPES.invite]: 'invite-action-buttons',
        [MEMBERS_TAB_TYPES.accessRequest]: 'access-request-action-buttons',
        ...ACTION_BUTTONS,
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
