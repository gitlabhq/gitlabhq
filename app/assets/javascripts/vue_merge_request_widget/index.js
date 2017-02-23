const Timeago = require('timeago.js');
const Vue = window.Vue = require('vue');
const WidgetHeader = require('./components/mr_widget_header.js');
const MergedState = require('./components/states/mr_widget_merged.js');
const ClosedState = require('./components/states/mr_widget_closed.js');
const LockedState = require('./components/states/mr_widget_locked.js');
const WipState = require('./components/states/mr_widget_wip.js');
const ArchivedState = require('./components/states/mr_widget_archived.js');
const MRWidgetStore = require('./stores/merge_request_store.js');

window.gl = window.gl || {};
window.gl.mrWidget = window.gl.mrWidget || {};

gl.mrWidget.timeagoInstance = new Timeago();

$(() => {
  gl.mrWidget.instance = new Vue({
    el: document.querySelector('.vue-merge-request-widget'),
    name: 'MRWidget',
    data() {
      const store = new MRWidgetStore(gl.mrWidgetData);
      return {
        mr: store,
      };
    },
    components: {
      'mr-widget-header': WidgetHeader,
      'mr-widget-merged': MergedState,
      'mr-widget-closed': ClosedState,
      'mr-widget-locked': LockedState,
      'mr-widget-wip': WipState,
      'mr-widget-archived': ArchivedState,
    },
    template: `
      <div class="mr-state-widget">
        <mr-widget-header
          :targetBranch="mr.targetBranch"
          :sourceBranch="mr.sourceBranch"
        />

        <mr-widget-merged :mr="mr" v-if="mr.isMerged" />
        <mr-widget-closed :mr="mr" v-if="mr.isClosed" />
        <mr-widget-locked :mr="mr" v-if="mr.isLocked" />
        <mr-widget-archived v-if="mr.isArchived" />
        <mr-widget-wip v-if="mr.isWip" />

      </div>
    `,
  });
});
