<script>
import { EVENT_UPDATED_I18N, VARIANT_DEFAULT } from '../../constants';
import { getValueByEventTarget, isValidVariant } from '../../utils';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventUpdated',
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
      return getValueByEventTarget(EVENT_UPDATED_I18N, this.event);
    },
  },
};
</script>

<template>
  <contribution-event-base
    :event="event"
    :message="message"
    :variant="variant"
    icon-name="pencil"
  />
</template>
