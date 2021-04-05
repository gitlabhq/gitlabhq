<script>
import { s__, sprintf } from '~/locale';
import ActionButtonGroup from './action_button_group.vue';
import RemoveMemberButton from './remove_member_button.vue';
import ResendInviteButton from './resend_invite_button.vue';

export default {
  name: 'InviteActionButtons',
  components: { ActionButtonGroup, RemoveMemberButton, ResendInviteButton },
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
        { inviteEmail: invite.email, source: source.fullName },
      );
    },
  },
};
</script>

<template>
  <action-button-group>
    <div v-if="permissions.canResend" class="gl-px-1">
      <resend-invite-button :member-id="member.id" />
    </div>
    <div v-if="permissions.canRemove" class="gl-px-1">
      <remove-member-button
        :member-id="member.id"
        :message="message"
        :title="s__('Member|Revoke invite')"
        is-invite
      />
    </div>
  </action-button-group>
</template>
