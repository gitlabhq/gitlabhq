<script>
import { GlButton, GlLink } from '@gitlab/ui';
import ExperimentTracking from '~/experimentation/experiment_tracking';
import { s__ } from '~/locale';
import eventHub from '../event_hub';

export default {
  components: { GlButton, GlLink },
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
      required: true,
    },
    trackExperiment: {
      type: String,
      required: false,
      default: undefined,
    },
    triggerElement: {
      type: String,
      required: false,
      default: 'button',
    },
    event: {
      type: String,
      required: false,
      default: '',
    },
    label: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isButton() {
      return this.triggerElement === 'button';
    },
    componentAttributes() {
      const baseAttributes = {
        class: this.classes,
        'data-qa-selector': 'invite_members_button',
      };

      if (this.event && this.label) {
        return {
          ...baseAttributes,
          'data-track-event': this.event,
          'data-track-label': this.label,
        };
      }

      return baseAttributes;
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
    v-if="isButton"
    v-bind="componentAttributes"
    :variant="variant"
    :icon="icon"
    @click="openModal"
  >
    {{ displayText }}
  </gl-button>
  <gl-link v-else v-bind="componentAttributes" data-is-link="true" @click="openModal">
    {{ displayText }}
  </gl-link>
</template>
