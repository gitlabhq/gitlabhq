import Vue from 'vue';
import WidgetHeader from './components/mr_widget_header';
import WidgetMergeHelp from './components/mr_widget_merge_help';
import WidgetPipeline from './components/mr_widget_pipeline';
import WidgetDeployment from './components/mr_widget_deployment';
import WidgetRelatedLinks from './components/mr_widget_related_links';
import MergedState from './components/states/mr_widget_merged';
import ClosedState from './components/states/mr_widget_closed';
import LockedState from './components/states/mr_widget_locked';
import WipState from './components/states/mr_widget_wip';
import ArchivedState from './components/states/mr_widget_archived';
import ConflictsState from './components/states/mr_widget_conflicts';
import NothingToMergeState from './components/states/mr_widget_nothing_to_merge';
import MissingBranchState from './components/states/mr_widget_missing_branch';
import NotAllowedState from './components/states/mr_widget_not_allowed';
import ReadyToMergeState from './components/states/mr_widget_ready_to_merge';
import UnresolvedDiscussionsState from './components/states/mr_widget_unresolved_discussions';
import PipelineBlockedState from './components/states/mr_widget_pipeline_blocked';
import PipelineFailedState from './components/states/mr_widget_pipeline_failed';
import MergeWhenPipelineSucceedsState from './components/states/mr_widget_merge_when_pipeline_succeeds';
import CheckingState from './components/states/mr_widget_checking';
import MRWidgetStore from './stores/mr_widget_store';
import MRWidgetService from './services/mr_widget_service';
import { stateToComponentMap, statesToShowHelpWidget } from './stores/state_maps';

const mrWidgetOptions = () => ({
  el: '#js-vue-mr-widget',
  name: 'MRWidget',
  data() {
    const store = new MRWidgetStore(gl.mrWidgetData);
    const service = new MRWidgetService(store);
    return {
      mr: store,
      service,
    };
  },
  computed: {
    componentName() {
      return stateToComponentMap[this.mr.state];
    },
    shouldRenderMergeHelp() {
      return statesToShowHelpWidget.indexOf(this.mr.state) > -1;
    },
    shouldRenderPipelines() {
      return this.mr.pipeline;
    },
    shouldRenderRelatedLinks() {
      return this.mr.relatedLinks;
    },
    shouldRenderDeployments() {
      return this.mr.deployments.length;
    },
  },
  mounted() {
    this.service.fetchDeployments();
  },
  components: {
    'mr-widget-header': WidgetHeader,
    'mr-widget-merge-help': WidgetMergeHelp,
    'mr-widget-pipeline': WidgetPipeline,
    'mr-widget-deployment': WidgetDeployment,
    'mr-widget-related-links': WidgetRelatedLinks,
    'mr-widget-merged': MergedState,
    'mr-widget-closed': ClosedState,
    'mr-widget-locked': LockedState,
    'mr-widget-wip': WipState,
    'mr-widget-archived': ArchivedState,
    'mr-widget-conflicts': ConflictsState,
    'mr-widget-nothing-to-merge': NothingToMergeState,
    'mr-widget-not-allowed': NotAllowedState,
    'mr-widget-missing-branch': MissingBranchState,
    'mr-widget-ready-to-merge': ReadyToMergeState,
    'mr-widget-checking': CheckingState,
    'mr-widget-unresolved-discussions': UnresolvedDiscussionsState,
    'mr-widget-pipeline-blocked': PipelineBlockedState,
    'mr-widget-pipeline-failed': PipelineFailedState,
    'mr-widget-merge-when-pipeline-succeeds': MergeWhenPipelineSucceedsState,
  },
  template: `
    <div class="mr-state-widget prepend-top-default">
      <mr-widget-header :mr="mr" />
      <mr-widget-pipeline v-if="shouldRenderPipelines" :mr="mr" />
      <mr-widget-deployment v-if="shouldRenderDeployments" :mr="mr" />
      <component :is="componentName" :mr="mr" :service="service" />
      <mr-widget-related-links v-if="shouldRenderRelatedLinks" :related-links="mr.relatedLinks" />
      <mr-widget-merge-help v-if="shouldRenderMergeHelp" />
    </div>
  `,
});

document.addEventListener('DOMContentLoaded', () => new Vue(mrWidgetOptions()));
