/* global Vue */

require('./components/time_tracker');
require('../../smart_interval');
require('../../subbable_resource');

(() => {
  /* This Vue instance represents what will become the parent instance for the
    * sidebar. It will be responsible for managing `issuable` state and propagating
    * changes to sidebar components. We will want to create a separate service to
    * interface with the server at that point.
   */

  class IssuableTimeTracking {
    constructor(issuableJSON) {
      const parsedIssuable = JSON.parse(issuableJSON);
      return this.initComponent(parsedIssuable);
    }

    initComponent(parsedIssuable) {
      this.parentInstance = new Vue({
        el: '#issuable-time-tracker',
        data: {
          issuable: parsedIssuable,
        },
        methods: {
          fetchIssuable() {
            return gl.IssuableResource.get.call(gl.IssuableResource, {
              type: 'GET',
              url: gl.IssuableResource.endpoint,
            });
          },
          updateState(data) {
            this.issuable = data;
          },
          subscribeToUpdates() {
            gl.IssuableResource.subscribe(data => this.updateState(data));
          },
          listenForSlashCommands() {
            $(document).on('ajax:success', '.gfm-form', (e, data) => {
              const subscribedCommands = ['spend_time', 'time_estimate'];
              const changedCommands = data.commands_changes;

              if (changedCommands && _.intersection(subscribedCommands, changedCommands).length) {
                this.fetchIssuable();
              }
            });
          },
        },
        created() {
          this.fetchIssuable();
        },
        mounted() {
          this.subscribeToUpdates();
          this.listenForSlashCommands();
        },
      });
    }
  }

  gl.IssuableTimeTracking = IssuableTimeTracking;
})(window.gl || (window.gl = {}));
