<script>
import {
  EVENT_REOPENED_I18N,
  EVENT_REOPENED_ICONS,
  VARIANT_DEFAULT,
} from 'ee_else_ce/contribution_events/constants';
import { getValueByEventTarget, isValidVariant } from '../../utils';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventReopened',
  components: { ContributionEventBase },
  props: {
    event: {
      type: Object,
      required: true,
    },
    variant: {
      type: String,
      required: false,
      default: VARIANT_DEFAULT,
      validator: isValidVariant,
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
  <contribution-event-base
    :event="event"
    :message="message"
    :variant="variant"
    :icon-name="iconName"
  />
</template>
