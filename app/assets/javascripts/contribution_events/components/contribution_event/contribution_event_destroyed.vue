<script>
import { EVENT_DESTROYED_I18N, EVENT_DESTROYED_ICONS, VARIANT_DEFAULT } from '../../constants';
import { getValueByEventTarget, isValidVariant } from '../../utils';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventDestroyed',
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
      return getValueByEventTarget(EVENT_DESTROYED_I18N, this.event);
    },
    iconName() {
      return getValueByEventTarget(EVENT_DESTROYED_ICONS, this.event);
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
