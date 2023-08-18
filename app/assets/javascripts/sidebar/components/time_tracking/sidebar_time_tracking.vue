<script>
import $ from 'jquery';
import { intersection } from 'lodash';

import '~/smart_interval';

import eventHub from '../../event_hub';
import IssuableTimeTracker from './time_tracker.vue';

export default {
  components: {
    IssuableTimeTracker,
  },
  props: {
    fullPath: {
      type: String,
      required: false,
      default: '',
    },
    issuableId: {
      type: String,
      required: true,
    },
    issuableIid: {
      type: String,
      required: true,
    },
    limitToHours: {
      type: Boolean,
      required: false,
      default: false,
    },
    canAddTimeEntries: {
      type: Boolean,
      required: false,
      default: true,
    },
    canSetTimeEstimate: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  mounted() {
    this.listenForQuickActions();
  },
  methods: {
    listenForQuickActions() {
      $(document).on('ajax:success', '.gfm-form', this.quickActionListened);

      eventHub.$on('timeTrackingUpdated', (data) => {
        this.quickActionListened({ detail: [data] });
      });
    },
    quickActionListened(e) {
      const data = e.detail[0];

      const subscribedCommands = ['spend_time', 'time_estimate'];
      let changedCommands;
      if (data !== undefined) {
        changedCommands = data.commands_changes ? Object.keys(data.commands_changes) : [];
      } else {
        changedCommands = [];
      }
      if (changedCommands && intersection(subscribedCommands, changedCommands).length) {
        eventHub.$emit('timeTracker:refresh');
      }
    },
  },
};
</script>

<template>
  <div class="block time-tracking">
    <issuable-time-tracker
      :full-path="fullPath"
      :issuable-id="issuableId"
      :issuable-iid="issuableIid"
      :limit-to-hours="limitToHours"
      :can-add-time-entries="canAddTimeEntries"
      :can-set-time-estimate="canSetTimeEstimate"
    />
  </div>
</template>
