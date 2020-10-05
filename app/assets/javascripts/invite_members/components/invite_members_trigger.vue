<script>
import { GlLink, GlIcon } from '@gitlab/ui';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: {
    GlLink,
    GlIcon,
  },
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
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal');
    },
  },
};
</script>

<template>
  <gl-link @click="openModal">
    <div v-if="icon" class="nav-icon-container">
      <gl-icon :size="16" :name="icon" />
    </div>
    <span class="nav-item-name"> {{ displayText }} </span>
  </gl-link>
</template>
