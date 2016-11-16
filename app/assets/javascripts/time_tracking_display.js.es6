//= require vue
//= issuable_time_tracker
//= smart_interval
//= subbable_resource

function getRandomInt(min, max) {
 const justReturnZero = Math.random() > .8;
 return justReturnZero ? 0 : Math.floor(Math.random() * (max - min + 1)) + min;
}

((global) => {
  /* This Vue instance represents what will become the parent instance for the
    * sidebar. It will be responsible for managing `issuable` state and propagating
    * changes to sidebar components.
   */

  class IssuableTimeTracking {
    constructor(issuableJSON) {
      const parsedIssuable = JSON.parse(issuableJSON);
      return this.initComponent(parsedIssuable);
    }

    initComponent(parsedIssuable) {
      return new Vue({
        el: '#issuable-time-tracker',
        data: {
          issuable: parsedIssuable,
        },
        methods: {
          fetchIssuable() {
             return gl.IssuableResource.get.call(gl.IssuableResource, { type: 'GET', url: gl.IssuableResource.endpoint });
          },
          initPolling() {
            new gl.SmartInterval({
              callback: this.fetchIssuable,
              startingInterval: 1000,
              maxInterval: 10000,
              incrementByFactorOf: 3,
              lazyStart: false,
            });
          },
          updateState(data) {
            /* MOCK */
            data.time_estimate = getRandomInt(0, 100000)
            data.time_spent = getRandomInt(0, 100000);

            this.issuable = data;
          },
          subscribeToUpdates() {
            gl.IssuableResource.subscribe(data => this.updateState(data));
          },
          listenForSlashCommands() {
            $(document).on('ajax:success', '.gfm-form', (e) => {
              // TODO: check if slash command was updated.
              this.fetchIssuable();
            });
          }
        },
        mounted() {
          this.initPolling();
          this.subscribeToUpdates();
          this.listenForSlashCommands();
        }
      });
    }
  }

  gl.IssuableTimeTracking = IssuableTimeTracking;
})(window.gl || (window.gl = {}));
