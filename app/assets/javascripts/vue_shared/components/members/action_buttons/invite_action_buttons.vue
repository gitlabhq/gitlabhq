<script>
import ActionButtonGroup from './action_button_group.vue';
import RemoveMemberButton from './remove_member_button.vue';
import { s__, sprintf } from '~/locale';

export default {
  name: 'InviteActionButtons',
  components: { ActionButtonGroup, RemoveMemberButton },
  props: {
    member: {
      type: Object,
      required: true,
    },
    permissions: {
      type: Object,
      required: true,
    },
  },
  computed: {
    message() {
      const { invite, source } = this.member;

      return sprintf(
        s__(
          'Members|Are you sure you want to revoke the invitation for %{inviteEmail} to join "%{source}"',
        ),
        { inviteEmail: invite.email, source: source.name },
      );
    },
  },
};
</script>

<template>
  <action-button-group>
    <!-- Resend button will go here -->
    <div v-if="permissions.canRemove" class="gl-px-1">
      <remove-member-button
        :member-id="member.id"
        :message="message"
        :title="s__('Member|Revoke invite')"
      />
    </div>
  </action-button-group>
</template>
