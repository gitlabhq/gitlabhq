import Vue from 'vue';
import WidgetHeader from './components/mr_widget_header';
import MergedState from './components/states/mr_widget_merged';
import ClosedState from './components/states/mr_widget_closed';
import LockedState from './components/states/mr_widget_locked';
import WipState from './components/states/mr_widget_wip';
import ArchivedState from './components/states/mr_widget_archived';
import MRWidgetStore from './stores/merge_request_store';

const mrWidgetOptions = () => ({
  el: '#js-vue-mr-widget',
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

document.addEventListener('DOMContentLoaded', () => {
  new Vue(mrWidgetOptions()); // eslint-disable-line
});
