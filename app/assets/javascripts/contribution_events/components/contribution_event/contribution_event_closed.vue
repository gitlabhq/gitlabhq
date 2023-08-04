<script>
import {
  EVENT_CLOSED_I18N,
  TARGET_TYPE_MERGE_REQUEST,
  EVENT_CLOSED_ICONS,
} from 'ee_else_ce/contribution_events/constants';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventClosed',
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
    targetType() {
      return this.target.type;
    },
    issueType() {
      return this.target.issue_type;
    },
    message() {
      return EVENT_CLOSED_I18N[this.issueType || this.targetType] || EVENT_CLOSED_I18N.fallback;
    },
    iconName() {
      return EVENT_CLOSED_ICONS[this.issueType || this.targetType] || EVENT_CLOSED_ICONS.fallback;
    },
    iconClass() {
      return this.targetType === TARGET_TYPE_MERGE_REQUEST ? 'gl-text-red-500' : 'gl-text-blue-500';
    },
  },
};
</script>

<template>
  <contribution-event-base
    :event="event"
    :message="message"
    :icon-name="iconName"
    :icon-class="iconClass"
  />
</template>
