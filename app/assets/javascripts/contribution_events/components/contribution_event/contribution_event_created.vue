<script>
import {
  EVENT_CREATED_I18N,
  TARGET_TYPE_WORK_ITEM,
  TARGET_TYPE_DESIGN,
} from 'ee_else_ce/contribution_events/constants';
import ContributionEventBase from './contribution_event_base.vue';

export default {
  name: 'ContributionEventCreated',
  i18n: EVENT_CREATED_I18N,
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
      if (!this.target) {
        return this.$options.i18n[this.resourceParent.type] || this.$options.i18n.fallback;
      }

      if (this.target.type === TARGET_TYPE_WORK_ITEM) {
        return this.$options.i18n[this.target.issue_type] || this.$options.i18n.fallback;
      }

      return this.$options.i18n[this.target.type] || this.$options.i18n.fallback;
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
