<script>
import InviteMemberModal from '~/invite_member/components/invite_member_modal.vue';
import InviteMemberTrigger from '~/invite_member/components/invite_member_trigger.vue';
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __ } from '~/locale';

export default {
  displayText: __('Invite members'),
  dataTrackLabel: 'edit_assignee',
  components: {
    InviteMemberTrigger,
    InviteMemberModal,
    InviteMembersTrigger,
  },
  inject: {
    projectMembersPath: {
      default: '',
    },
    directlyInviteMembers: {
      default: false,
    },
  },
  computed: {
    trackEvent() {
      return this.directlyInviteMembers ? 'click_invite_members' : 'click_invite_members_version_b';
    },
  },
};
</script>

<template>
  <div>
    <invite-members-trigger
      v-if="directlyInviteMembers"
      trigger-element="anchor"
      :display-text="$options.displayText"
      :event="trackEvent"
      :label="$options.dataTrackLabel"
      classes="gl-display-block gl-pl-6 gl-hover-text-decoration-none gl-hover-text-blue-800!"
    />
    <template v-else>
      <invite-member-trigger
        :display-text="$options.displayText"
        :event="trackEvent"
        :label="$options.dataTrackLabel"
        class="gl-display-block gl-pl-6 gl-hover-text-decoration-none gl-hover-text-blue-800!"
      />
      <invite-member-modal :members-path="projectMembersPath" />
    </template>
  </div>
</template>
