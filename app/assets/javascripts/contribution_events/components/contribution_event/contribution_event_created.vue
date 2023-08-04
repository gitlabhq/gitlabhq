<script>
import { EVENT_CREATED_I18N, TARGET_TYPE_DESIGN } from 'ee_else_ce/contribution_events/constants';
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
    issueType() {
      return this.target.issue_type;
    },
    message() {
      if (!this.target) {
        return EVENT_CREATED_I18N[this.resourceParent.type] || EVENT_CREATED_I18N.fallback;
      }

      return EVENT_CREATED_I18N[this.issueType || this.target.type] || EVENT_CREATED_I18N.fallback;
    },
    iconName() {
      switch (this.target?.type) {
        case TARGET_TYPE_DESIGN:
          return 'upload';

        default:
          return 'status_open';
      }
    },
    iconClass() {
      switch (this.target?.type) {
        case TARGET_TYPE_DESIGN:
          return null;

        default:
          return 'gl-text-green-500';
      }
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
