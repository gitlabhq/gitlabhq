import '~/smart_interval';

import timeTracker from './time_tracker';

import Store from '../../stores/sidebar_store';
import Mediator from '../../sidebar_mediator';

export default {
  data() {
    return {
      mediator: new Mediator(),
      store: new Store(),
    };
  },
  components: {
    'issuable-time-tracker': timeTracker,
  },
  methods: {
    listenForSlashCommands() {
      $(document).on('ajax:success', '.gfm-form', this.slashCommandListened);
    },
    slashCommandListened(e, data) {
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
