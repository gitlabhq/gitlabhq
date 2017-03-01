import Vue from 'vue';
import WidgetHeader from './components/mr_widget_header';
import MergedState from './components/states/mr_widget_merged';
import ClosedState from './components/states/mr_widget_closed';
import LockedState from './components/states/mr_widget_locked';
import WipState from './components/states/mr_widget_wip';
import ArchivedState from './components/states/mr_widget_archived';
import ConflictsState from './components/states/mr_widget_conflicts';
import NothingToMergeState from './components/states/mr_widget_nothing_to_merge';
import MissingBranchState from './components/states/mr_widget_missing_branch';
import NotAllowedState from './components/states/mr_widget_not_allowed';
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
    'mr-widget-conflicts': ConflictsState,
    'mr-widget-nothing-to-merge': NothingToMergeState,
    'mr-widget-not-allowed': NotAllowedState,
    'mr-widget-missing-branch': MissingBranchState,
  },
  template: `
    <div class="mr-state-widget">
      <mr-widget-header
        :targetBranch="mr.targetBranch"
        :sourceBranch="mr.sourceBranch"
      />

      <mr-widget-merged :mr="mr" v-if="mr.state === 'merged'" />
      <mr-widget-closed :mr="mr" v-if="mr.state === 'closed'" />
      <mr-widget-locked :mr="mr" v-if="mr.state === 'locked'" />
      <mr-widget-conflicts :mr="mr" v-if="mr.state === 'conflicts'" />
      <mr-widget-missing-branch :mr="mr" v-if="mr.state === 'missingBranch'" />
      <mr-widget-wip :mr="mr" v-if="mr.state === 'workInProgress'" />
      <mr-widget-nothing-to-merge v-if="mr.state === 'nothingToMerge'" />
      <mr-widget-not-allowed v-if="mr.state === 'notAllowedToMerge'" />
      <mr-widget-archived v-if="mr.state === 'archived'" />
    </div>
  `,
});

document.addEventListener('DOMContentLoaded', () => {
  new Vue(mrWidgetOptions()); // eslint-disable-line
});
