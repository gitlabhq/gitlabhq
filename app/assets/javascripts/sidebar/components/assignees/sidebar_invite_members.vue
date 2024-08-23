<script>
import InviteMembersTrigger from '~/invite_members/components/invite_members_trigger.vue';
import { __ } from '~/locale';

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
  },
};
</script>

<template>
  <invite-members-trigger
    trigger-element="anchor"
    :display-text="$options.displayText"
    :trigger-source="triggerSource"
    classes="gl-block gl-pl-0 hover:gl-no-underline hover:!gl-text-blue-800"
  />
</template>
