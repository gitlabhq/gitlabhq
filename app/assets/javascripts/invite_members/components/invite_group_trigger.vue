<script>
import { GlButton } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlButton,
  },
  props: {
    displayText: {
      type: String,
      required: false,
      default: s__('InviteMembers|Invite a group'),
    },
    classes: {
      type: String,
      required: false,
      default: '',
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal', { inviteeType: 'group' });
    },
  },
};
</script>

<template>
  <gl-button :class="classes" data-qa-selector="invite_a_group_button" @click="openModal">
    {{ displayText }}
  </gl-button>
</template>
