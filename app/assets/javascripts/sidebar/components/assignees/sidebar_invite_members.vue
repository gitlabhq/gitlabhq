<script>
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __ } from '~/locale';

export default {
  displayText: __('Invite members'),
  dataTrackLabel: 'edit_assignee',
  dataTrackEvent: 'click_invite_members',
  components: {
    InviteMembersTrigger,
  },
};
</script>

<template>
  <invite-members-trigger
    trigger-element="anchor"
    :display-text="$options.displayText"
    :event="$options.dataTrackEvent"
    :label="$options.dataTrackLabel"
    classes="gl-display-block gl-pl-6 gl-hover-text-decoration-none gl-hover-text-blue-800!"
  />
</template>
