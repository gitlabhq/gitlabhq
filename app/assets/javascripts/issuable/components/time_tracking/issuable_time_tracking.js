import '~/smart_interval';

import timeTracker from './time_tracker';
import eventHub from '../../event_hub';

export default {
  el: '#issuable-time-tracker',
  data() {
    const selector = this.$options.el;
    const element = document.querySelector(selector);

    const docsUrl = element.dataset.docsUrl;

    return {
      issuable: {},
      docsUrl,
    };
  },
  components: {
    'issuable-time-tracker': timeTracker,
  },
  methods: {
    fetchIssuable() {
      eventHub.$emit('fetchIssuable');
    },
    updateState(data) {
      this.issuable = data;
    },
    listenForSlashCommands() {
      $(document).on('ajax:success', '.gfm-form', (e, data) => {
        const subscribedCommands = ['spend_time', 'time_estimate'];
        const changedCommands = data.commands_changes
          ? Object.keys(data.commands_changes)
          : [];
        if (changedCommands && _.intersection(subscribedCommands, changedCommands).length) {
          this.fetchIssuable();
        }
      });
    },
  },
  created() {
    eventHub.$on('receivedIssuable', data => this.updateState(data));
  },
  mounted() {
    this.fetchIssuable();
    this.listenForSlashCommands();
  },
  template: `
    <div class="block">
      <issuable-time-tracker
        :time_estimate="issuable.time_estimate"
        :time_spent="issuable.total_time_spent"
        :human_time_estimate="issuable.human_time_estimate"
        :human_time_spent="issuable.human_total_time_spent"
        :docs-url="docsUrl"
      />
    </div>
  `,
};
