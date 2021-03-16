<script>
import { GlButton } from '@gitlab/ui';
import ExperimentTracking from '~/experimentation/experiment_tracking';
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
    triggerSource: {
      type: String,
      required: false,
      default: 'unknown',
    },
    trackExperiment: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  mounted() {
    this.trackExperimentOnShow();
  },
  methods: {
    openModal() {
      eventHub.$emit('openModal', { inviteeType: 'members', source: this.triggerSource });
    },
    trackExperimentOnShow() {
      if (this.trackExperiment) {
        const tracking = new ExperimentTracking(this.trackExperiment);
        tracking.event('comment_invite_shown');
      }
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
