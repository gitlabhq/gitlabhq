<script>
import ActionButtonGroup from './action_button_group.vue';
import RemoveMemberButton from './remove_member_button.vue';
import LeaveButton from './leave_button.vue';
import { s__, sprintf } from '~/locale';

export default {
  name: 'UserActionButtons',
  components: {
    ActionButtonGroup,
    RemoveMemberButton,
    LeaveButton,
    LdapOverrideButton: () =>
      import('ee_component/members/components/ldap/ldap_override_button.vue'),
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
    isCurrentUser: {
      type: Boolean,
      required: true,
    },
    permissions: {
      type: Object,
      required: true,
    },
  },
  computed: {
    message() {
      const { user, source } = this.member;

      if (user) {
        return sprintf(
          s__('Members|Are you sure you want to remove %{usersName} from "%{source}"'),
          {
            usersName: user.name,
            source: source.name,
          },
        );
      }

      return sprintf(
        s__('Members|Are you sure you want to remove this orphaned member from "%{source}"'),
        {
          source: source.name,
        },
      );
    },
  },
};
</script>

<template>
  <action-button-group>
    <div v-if="permissions.canRemove" class="gl-px-1">
      <leave-button v-if="isCurrentUser" :member="member" />
      <remove-member-button
        v-else
        :member-id="member.id"
        :message="message"
        :title="s__('Member|Remove member')"
      />
    </div>
    <div v-else-if="permissions.canOverride && !member.isOverridden" class="gl-px-1">
      <ldap-override-button :member="member" />
    </div>
  </action-button-group>
</template>
