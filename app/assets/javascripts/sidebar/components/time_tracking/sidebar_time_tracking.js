import '~/smart_interval';

import timeTracker from './time_tracker';
import eventHub from '../../event_hub';

import store from '../../stores/sidebar_store';
import mediator from '../../sidebar_mediator';

export default {
  data() {
    return {
      store,
    };
  },
  components: {
    'issuable-time-tracker': timeTracker,
  },
  methods: {
    listenForSlashCommands() {
      $(document).on('ajax:success', '.gfm-form', (e, data) => {
        const subscribedCommands = ['spend_time', 'time_estimate'];
        const changedCommands = data.commands_changes
          ? Object.keys(data.commands_changes)
          : [];
        if (changedCommands && _.intersection(subscribedCommands, changedCommands).length) {
          mediator.fetch();
        }
      });
    },
  },
  mounted() {
    this.listenForSlashCommands();
  },
  template: `
    <div class="block">
      <issuable-time-tracker
        :time_estimate="store.timeEstimate"
        :time_spent="store.totalTimeSpent"
        :human_time_estimate="store.humanTimeEstimate"
        :human_time_spent="store.humanTotalTimeSpent"
        :rootPath="store.rootPath"
      />
    </div>
  `,
};
