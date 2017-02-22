const Timeago      = require('timeago.js');
window.Vue         = require('vue');
window.gl          = window.gl || {};
window.gl.mrWidget = window.gl.mrWidget || {};

gl.mrWidget.Header   = require('./components/mr_widget_header.js');
gl.mrWidget.Merged   = require('./components/states/mr_widget_merged.js');
gl.mrWidget.Closed   = require('./components/states/mr_widget_closed.js');
gl.mrWidget.Locked   = require('./components/states/mr_widget_locked.js');
gl.mrWidget.Wip      = require('./components/states/mr_widget_wip.js');
gl.mrWidget.Archived = require('./components/states/mr_widget_archived.js');
gl.mrWidget.Store    = require('./stores/merge_request_store.js');

gl.mrWidget.timeagoInstance = new Timeago();


$(() => {
  new Vue({
    el: document.querySelector('.vue-merge-request-widget'),
    name: 'MRWidget',
    data() {
      return {
        mr: new gl.mrWidget.Store(gl.mrWidgetData)
      }
    },
    components: {
      'mr-widget-header': gl.mrWidget.Header,
      'mr-widget-merged': gl.mrWidget.Merged,
      'mr-widget-closed': gl.mrWidget.Closed,
      'mr-widget-locked': gl.mrWidget.Locked,
      'mr-widget-wip': gl.mrWidget.Wip,
      'mr-widget-archived': gl.mrWidget.Archived,
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
        <mr-widget-archived :mr="mr" v-if="mr.isArchived" />
        <mr-widget-wip :mr="mr" v-if="mr.isWip" />

      </div>
    `,
  });
})
