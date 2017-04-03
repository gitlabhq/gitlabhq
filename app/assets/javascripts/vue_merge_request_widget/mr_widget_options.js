import {
  WidgetHeader,
  WidgetMergeHelp,
  WidgetPipeline,
  WidgetDeployment,
  WidgetRelatedLinks,
  MergedState,
  ClosedState,
  LockedState,
  WipState,
  ArchivedState,
  ConflictsState,
  NothingToMergeState,
  MissingBranchState,
  NotAllowedState,
  ReadyToMergeState,
  UnresolvedDiscussionsState,
  PipelineBlockedState,
  PipelineFailedState,
  FailedToMerge,
  MergeWhenPipelineSucceedsState,
  CheckingState,
  MRWidgetStore,
  MRWidgetService,
  eventHub,
  stateToComponentMap,
  statesToShowHelpWidget,
} from './dependencies';

export default {
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
      return Object.keys(this.mr.pipeline).length || this.mr.hasCI;
    },
    shouldRenderRelatedLinks() {
      return this.mr.relatedLinks;
    },
    shouldRenderDeployments() {
      return this.mr.deployments.length;
    },
  },
  methods: {
    checkStatus(cb) {
      // TODO: Error handling
      this.service.checkStatus()
        .then(res => res.json())
        .then((res) => {
          this.mr.setData(res);
          if (cb) {
            cb.call(null, res);
          }
        });
    },
    initCIPolling() {
      this.ciStatusInterval = new gl.SmartInterval({
        callback: this.getCIStatus,
        startingInterval: 10000,
        maxInterval: 30000,
        hiddenInterval: 120000,
        incrementByFactorOf: 5000,
      });
    },
    getCIStatus() {
      // TODO: Error handling
      this.service.ciStatusResorce.get()
        .then(res => res.json())
        .then((res) => {
          if (res.has_ci) {
            this.mr.updatePipelineData(res);
          }
        });
    },
  },
  created() {
    eventHub.$on('MRWidgetUpdateRequested', (cb) => {
      this.checkStatus(cb);
    });

    // `params` should be an Array contains a Boolean, like `[true]`
    // Passing parameter as Boolean didn't work.
    eventHub.$on('SetBranchRemoveFlag', (params) => {
      this.mr.isRemovingSourceBranch = params[0];
    });

    eventHub.$on('FailedToMerge', () => {
      this.mr.state = 'failedToMerge';
    });
  },
  mounted() {
    this.checkStatus();
    this.getCIStatus();

    // TODO: Error handling
    this.service.fetchDeployments()
      .then(res => res.json())
      .then((res) => {
        if (res.length) {
          this.mr.deployments = res;
        }
      });

    if (this.mr.hasCI) {
      this.initCIPolling();
    }
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
    'mr-widget-failed-to-merge': FailedToMerge,
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
      <mr-widget-deployment v-if="shouldRenderDeployments" :mr="mr" :service="service" />
      <component :is="componentName" :mr="mr" :service="service" />
      <mr-widget-related-links v-if="shouldRenderRelatedLinks" :related-links="mr.relatedLinks" />
      <mr-widget-merge-help v-if="shouldRenderMergeHelp" />
    </div>
  `,
};
