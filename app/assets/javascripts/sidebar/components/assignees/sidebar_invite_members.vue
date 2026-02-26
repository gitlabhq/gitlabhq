<script>
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __ } from '~/locale';
import { TYPE_MERGE_REQUEST } from '~/issues/constants';

export default {
  displayText: __('Invite members'),
  components: {
    InviteMembersTrigger,
  },
  props: {
    issuableType: {
      type: String,
      required: true,
    },
  },
  computed: {
    triggerSource() {
      return `${this.issuableType}_assignee_dropdown`;
    },
    inviteHelpText() {
      if (this.issuableType === TYPE_MERGE_REQUEST) {
        return __('Invite members to collaborate on changes to the repository.');
      }
      return __('Invite members to plan and track work.');
    },
  },
};
</script>

<template>
  <div class="gl-rounded-b-lg gl-bg-subtle gl-p-5">
    <p class="gl-mb-3">{{ inviteHelpText }}</p>
    <invite-members-trigger :display-text="$options.displayText" :trigger-source="triggerSource" />
  </div>
</template>
