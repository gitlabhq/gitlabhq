<script>
import {
  EVENT_CREATED_I18N,
  TARGET_TYPE_DESIGN,
  TYPE_FALLBACK,
} from 'ee_else_ce/contribution_events/constants';
import { getValueByEventTarget } from '../../utils';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventCreated',
  components: { ContributionEventBase },
  props: {
    event: {
      type: Object,
      required: true,
    },
  },
  computed: {
    target() {
      return this.event.target;
    },
    resourceParent() {
      return this.event.resource_parent;
    },
    message() {
      if (!this.target.type) {
        return EVENT_CREATED_I18N[this.resourceParent.type] || EVENT_CREATED_I18N[TYPE_FALLBACK];
      }

      return getValueByEventTarget(EVENT_CREATED_I18N, this.event);
    },
    iconName() {
      switch (this.target?.type) {
        case TARGET_TYPE_DESIGN:
          return 'upload';

        default:
          return 'status_open';
      }
    },
  },
};
</script>

<template>
  <contribution-event-base :event="event" :message="message" :icon-name="iconName" />
</template>
