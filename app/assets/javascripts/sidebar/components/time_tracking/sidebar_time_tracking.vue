<script>
import $ from 'jquery';
import _ from 'underscore';

import '~/smart_interval';

import IssuableTimeTracker from './time_tracker.vue';

import Store from '../../stores/sidebar_store';
import Mediator from '../../sidebar_mediator';
import eventHub from '../../event_hub';

export default {
  components: {
    IssuableTimeTracker,
  },
  data() {
    return {
      mediator: new Mediator(),
      store: new Store(),
    };
  },
  mounted() {
    this.listenForQuickActions();
  },
  methods: {
    listenForQuickActions() {
      $(document).on('ajax:success', '.gfm-form', this.quickActionListened);
      eventHub.$on('timeTrackingUpdated', (data) => {
        this.quickActionListened(null, data);
      });
    },
    quickActionListened(e, data) {
      const subscribedCommands = ['spend_time', 'time_estimate'];
      let changedCommands;
      if (data !== undefined) {
        changedCommands = data.commands_changes
          ? Object.keys(data.commands_changes)
          : [];
      } else {
        changedCommands = [];
      }
      if (changedCommands && _.intersection(subscribedCommands, changedCommands).length) {
        this.mediator.fetch();
      }
    },
  },
};
</script>

<template>
  <div class="block">
    <issuable-time-tracker
      :time_estimate="store.timeEstimate"
      :time_spent="store.totalTimeSpent"
      :human_time_estimate="store.humanTimeEstimate"
      :human_time_spent="store.humanTotalTimeSpent"
      :root-path="store.rootPath"
    />
  </div>
</template>
