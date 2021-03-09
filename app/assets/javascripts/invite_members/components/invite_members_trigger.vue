<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: { GlButton },
  props: {
    displayText: {
      type: String,
      required: false,
      default: s__('InviteMembers|Invite team members'),
    },
    icon: {
      type: String,
      required: false,
      default: '',
    },
    classes: {
      type: String,
      required: false,
      default: '',
    },
    variant: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal', { inviteeType: 'members' });
    },
  },
};
</script>

<template>
  <gl-button
    :class="classes"
    :icon="icon"
    :variant="variant"
    data-qa-selector="invite_members_button"
    @click="openModal"
  >
    {{ displayText }}
  </gl-button>
</template>
