<script>
import { EVENT_DESTROYED_I18N, EVENT_DESTROYED_ICONS } from '../../constants';
import { getValueByEventTarget } from '../../utils';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventDestroyed',
  components: { ContributionEventBase },
  props: {
    event: {
      type: Object,
      required: true,
    },
  },
  computed: {
    message() {
      return getValueByEventTarget(EVENT_DESTROYED_I18N, this.event);
    },
    iconName() {
      return getValueByEventTarget(EVENT_DESTROYED_ICONS, this.event);
    },
  },
};
</script>

<template>
  <contribution-event-base :event="event" :message="message" :icon-name="iconName" />
</template>
