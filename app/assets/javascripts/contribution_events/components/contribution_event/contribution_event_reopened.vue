<script>
import {
  EVENT_REOPENED_I18N,
  EVENT_REOPENED_ICONS,
} from 'ee_else_ce/contribution_events/constants';
import { getValueByEventTarget } from '../../utils';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventReopened',
  components: { ContributionEventBase },
  props: {
    event: {
      type: Object,
      required: true,
    },
  },
  computed: {
    message() {
      return getValueByEventTarget(EVENT_REOPENED_I18N, this.event);
    },
    iconName() {
      return getValueByEventTarget(EVENT_REOPENED_ICONS, this.event);
    },
  },
};
</script>

<template>
  <contribution-event-base :event="event" :message="message" :icon-name="iconName" />
</template>
