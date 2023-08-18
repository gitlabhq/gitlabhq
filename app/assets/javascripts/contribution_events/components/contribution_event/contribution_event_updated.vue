<script>
import { EVENT_UPDATED_I18N } from '../../constants';
import { getValueByEventTarget } from '../../utils';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventUpdated',
  components: { ContributionEventBase },
  props: {
    event: {
      type: Object,
      required: true,
    },
  },
  computed: {
    message() {
      return getValueByEventTarget(EVENT_UPDATED_I18N, this.event);
    },
  },
};
</script>

<template>
  <contribution-event-base :event="event" :message="message" icon-name="pencil" />
</template>
