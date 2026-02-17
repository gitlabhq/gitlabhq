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
    triggerSource: {
      type: String,
      required: true,
    },
  },
  methods: {
    openModal() {
      eventHub.$emit('open-group-modal', { source: this.triggerSource });
    },
  },
};
</script>

<template>
  <gl-button :class="classes" data-testid="invite-group-button" @click="openModal">
    {{ displayText }}
  </gl-button>
</template>
