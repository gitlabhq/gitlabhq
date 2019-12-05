<script>
import _ from 'underscore';
import { sprintf, s__, __ } from '~/locale';
import Project from '~/pages/projects/project';
import SmartInterval from '~/smart_interval';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import stateMaps from 'ee_else_ce/vue_merge_request_widget/stores/state_maps';
import createFlash from '../flash';
import Loading from './components/loading.vue';
import WidgetHeader from './components/mr_widget_header.vue';
import WidgetMergeHelp from './components/mr_widget_merge_help.vue';
import MrWidgetPipelineContainer from './components/mr_widget_pipeline_container.vue';
import Deployment from './components/deployment/deployment.vue';
import WidgetRelatedLinks from './components/mr_widget_related_links.vue';
import MrWidgetAlertMessage from './components/mr_widget_alert_message.vue';
import MergedState from './components/states/mr_widget_merged.vue';
import ClosedState from './components/states/mr_widget_closed.vue';
import MergingState from './components/states/mr_widget_merging.vue';
import RebaseState from './components/states/mr_widget_rebase.vue';
import WorkInProgressState from './components/states/work_in_progress.vue';
import ArchivedState from './components/states/mr_widget_archived.vue';
import ConflictsState from './components/states/mr_widget_conflicts.vue';
import NothingToMergeState from './components/states/nothing_to_merge.vue';
import MissingBranchState from './components/states/mr_widget_missing_branch.vue';
import NotAllowedState from './components/states/mr_widget_not_allowed.vue';
import ReadyToMergeState from './components/states/ready_to_merge.vue';
import ShaMismatchState from './components/states/sha_mismatch.vue';
import UnresolvedDiscussionsState from './components/states/unresolved_discussions.vue';
import PipelineBlockedState from './components/states/mr_widget_pipeline_blocked.vue';
import PipelineFailedState from './components/states/pipeline_failed.vue';
import FailedToMerge from './components/states/mr_widget_failed_to_merge.vue';
import MrWidgetAutoMergeEnabled from './components/states/mr_widget_auto_merge_enabled.vue';
import AutoMergeFailed from './components/states/mr_widget_auto_merge_failed.vue';
import CheckingState from './components/states/mr_widget_checking.vue';
import eventHub from './event_hub';
import notify from '~/lib/utils/notify';
import SourceBranchRemovalStatus from './components/source_branch_removal_status.vue';
import GroupedTestReportsApp from '../reports/components/grouped_test_reports_app.vue';
import { setFaviconOverlay } from '../lib/utils/common_utils';

export default {
  el: '#js-vue-mr-widget',
  // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/25
  // eslint-disable-next-line @gitlab/i18n/no-non-i18n-strings
  name: 'MRWidget',
  components: {
    Loading,
    'mr-widget-header': WidgetHeader,
    'mr-widget-merge-help': WidgetMergeHelp,
    MrWidgetPipelineContainer,
    Deployment,
    'mr-widget-related-links': WidgetRelatedLinks,
    MrWidgetAlertMessage,
    'mr-widget-merged': MergedState,
    'mr-widget-closed': ClosedState,
    'mr-widget-merging': MergingState,
    'mr-widget-failed-to-merge': FailedToMerge,
    'mr-widget-wip': WorkInProgressState,
    'mr-widget-archived': ArchivedState,
    'mr-widget-conflicts': ConflictsState,
    'mr-widget-nothing-to-merge': NothingToMergeState,
    'mr-widget-not-allowed': NotAllowedState,
    'mr-widget-missing-branch': MissingBranchState,
    'mr-widget-ready-to-merge': ReadyToMergeState,
    'sha-mismatch': ShaMismatchState,
    'mr-widget-checking': CheckingState,
    'mr-widget-unresolved-discussions': UnresolvedDiscussionsState,
    'mr-widget-pipeline-blocked': PipelineBlockedState,
    'mr-widget-pipeline-failed': PipelineFailedState,
    MrWidgetAutoMergeEnabled,
    'mr-widget-auto-merge-failed': AutoMergeFailed,
    'mr-widget-rebase': RebaseState,
    SourceBranchRemovalStatus,
    GroupedTestReportsApp,
  },
  props: {
    mrData: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    const store = this.mrData && new MRWidgetStore(this.mrData);

    return {
      mr: store,
      state: store && store.state,
      service: store && this.createService(store),
    };
  },
  computed: {
    componentName() {
      return stateMaps.stateToComponentMap[this.mr.state];
    },
    shouldRenderMergeHelp() {
      return stateMaps.statesToShowHelpWidget.indexOf(this.mr.state) > -1;
    },
    shouldRenderPipelines() {
      return this.mr.hasCI;
    },
    shouldRenderRelatedLinks() {
      return Boolean(this.mr.relatedLinks) && !this.mr.isNothingToMergeState;
    },
    shouldRenderSourceBranchRemovalStatus() {
      return (
        !this.mr.canRemoveSourceBranch &&
        this.mr.shouldRemoveSourceBranch &&
        (!this.mr.isNothingToMergeState && !this.mr.isMergedState)
      );
    },
    shouldRenderCollaborationStatus() {
      return this.mr.allowCollaboration && this.mr.isOpen;
    },
    shouldRenderMergedPipeline() {
      return this.mr.state === 'merged' && !_.isEmpty(this.mr.mergePipeline);
    },
    showMergePipelineForkWarning() {
      return Boolean(
        this.mr.mergePipelinesEnabled && this.mr.sourceProjectId !== this.mr.targetProjectId,
      );
    },
    mergeError() {
      return sprintf(s__('mrWidget|Merge failed: %{mergeError}. Please try again.'), {
        mergeError: this.mr.mergeError,
      });
    },
  },
  watch: {
    state(newVal, oldVal) {
      if (newVal !== oldVal && this.shouldRenderMergedPipeline) {
        // init polling
        this.initPostMergeDeploymentsPolling();
      }
    },
  },
  mounted() {
    if (gon && gon.features && gon.features.asyncMrWidget) {
      MRWidgetService.fetchInitialData()
        .then(({ data }) => this.initWidget(data))
        .catch(() =>
          createFlash(__('Unable to load the merge request widget. Try reloading the page.')),
        );
    } else {
      this.initWidget();
    }
  },
  beforeDestroy() {
    eventHub.$off('mr.discussion.updated', this.checkStatus);
    if (this.pollingInterval) {
      this.pollingInterval.destroy();
    }

    if (this.deploymentsInterval) {
      this.deploymentsInterval.destroy();
    }

    if (this.postMergeDeploymentsInterval) {
      this.postMergeDeploymentsInterval.destroy();
    }
  },
  methods: {
    initWidget(data = {}) {
      if (this.mr) {
        this.mr.setData({ ...window.gl.mrWidgetData, ...data });
      } else {
        this.mr = new MRWidgetStore({ ...window.gl.mrWidgetData, ...data });
      }

      if (!this.state) {
        this.state = this.mr.state;
      }

      if (!this.service) {
        this.service = this.createService(this.mr);
      }

      this.setFaviconHelper();
      this.initDeploymentsPolling();

      if (this.shouldRenderMergedPipeline) {
        this.initPostMergeDeploymentsPolling();
      }

      this.initPolling();
      this.bindEventHubListeners();
      eventHub.$on('mr.discussion.updated', this.checkStatus);
    },
    getServiceEndpoints(store) {
      return {
        mergePath: store.mergePath,
        mergeCheckPath: store.mergeCheckPath,
        cancelAutoMergePath: store.cancelAutoMergePath,
        removeWIPPath: store.removeWIPPath,
        sourceBranchPath: store.sourceBranchPath,
        ciEnvironmentsStatusPath: store.ciEnvironmentsStatusPath,
        mergeRequestBasicPath: store.mergeRequestBasicPath,
        mergeRequestWidgetPath: store.mergeRequestWidgetPath,
        mergeRequestCachedWidgetPath: store.mergeRequestCachedWidgetPath,
        mergeActionsContentPath: store.mergeActionsContentPath,
        rebasePath: store.rebasePath,
      };
    },
    createService(store) {
      return new MRWidgetService(this.getServiceEndpoints(store));
    },
    checkStatus(cb, isRebased) {
      return this.service
        .checkStatus()
        .then(({ data }) => {
          this.handleNotification(data);
          this.mr.setData(data, isRebased);
          this.setFaviconHelper();

          if (cb) {
            cb.call(null, data);
          }
        })
        .catch(() => createFlash(__('Something went wrong. Please try again.')));
    },
    setFaviconHelper() {
      if (this.mr.ciStatusFaviconPath) {
        return setFaviconOverlay(this.mr.ciStatusFaviconPath);
      }
      return Promise.resolve();
    },
    initPolling() {
      this.pollingInterval = new SmartInterval({
        callback: this.checkStatus,
        startingInterval: 10000,
        maxInterval: 30000,
        hiddenInterval: 120000,
        incrementByFactorOf: 5000,
      });
    },
    initDeploymentsPolling() {
      this.deploymentsInterval = this.deploymentsPoll(this.fetchPreMergeDeployments);
    },
    initPostMergeDeploymentsPolling() {
      this.postMergeDeploymentsInterval = this.deploymentsPoll(this.fetchPostMergeDeployments);
    },
    deploymentsPoll(callback) {
      return new SmartInterval({
        callback,
        startingInterval: 30000,
        maxInterval: 120000,
        hiddenInterval: 240000,
        incrementByFactorOf: 15000,
        immediateExecution: true,
      });
    },
    fetchDeployments(target) {
      return this.service.fetchDeployments(target);
    },
    fetchPreMergeDeployments() {
      return this.fetchDeployments()
        .then(({ data }) => {
          if (data.length) {
            this.mr.deployments = data;
          }
        })
        .catch(() => this.throwDeploymentsError());
    },
    fetchPostMergeDeployments() {
      return this.fetchDeployments('merge_commit')
        .then(({ data }) => {
          if (data.length) {
            this.mr.postMergeDeployments = data;
          }
        })
        .catch(() => this.throwDeploymentsError());
    },
    throwDeploymentsError() {
      createFlash(
        __(
          'Something went wrong while fetching the environments for this merge request. Please try again.',
        ),
      );
    },
    fetchActionsContent() {
      this.service
        .fetchMergeActionsContent()
        .then(res => {
          if (res.data) {
            const el = document.createElement('div');
            el.innerHTML = res.data;
            document.body.appendChild(el);
            Project.initRefSwitcher();
          }
        })
        .catch(() => createFlash(__('Something went wrong. Please try again.')));
    },
    handleNotification(data) {
      if (data.ci_status === this.mr.ciStatus) return;
      if (!data.pipeline) return;

      const { label } = data.pipeline.details.status;
      const title = sprintf(__('Pipeline %{label}'), { label });
      const message = sprintf(__('Pipeline %{label} for "%{dataTitle}"'), {
        dataTitle: data.title,
        label,
      });

      notify.notifyMe(title, message, this.mr.gitlabLogo);
    },
    resumePolling() {
      this.pollingInterval.resume();
    },
    stopPolling() {
      this.pollingInterval.stopTimer();
    },
    bindEventHubListeners() {
      eventHub.$on('MRWidgetUpdateRequested', cb => {
        this.checkStatus(cb);
      });

      eventHub.$on('MRWidgetRebaseSuccess', cb => {
        this.checkStatus(cb, true);
      });

      // `params` should be an Array contains a Boolean, like `[true]`
      // Passing parameter as Boolean didn't work.
      eventHub.$on('SetBranchRemoveFlag', params => {
        [this.mr.isRemovingSourceBranch] = params;
      });

      eventHub.$on('FailedToMerge', mergeError => {
        this.mr.state = 'failedToMerge';
        this.mr.mergeError = mergeError;
      });

      eventHub.$on('UpdateWidgetData', data => {
        this.mr.setData(data);
      });

      eventHub.$on('FetchActionsContent', () => {
        this.fetchActionsContent();
      });

      eventHub.$on('EnablePolling', () => {
        this.resumePolling();
      });

      eventHub.$on('DisablePolling', () => {
        this.stopPolling();
      });
    },
  },
};
</script>
<template>
  <div v-if="mr" class="mr-state-widget prepend-top-default">
    <mr-widget-header :mr="mr" />
    <mr-widget-pipeline-container
      v-if="shouldRenderPipelines"
      class="mr-widget-workflow"
      :mr="mr"
    />
    <div class="mr-section-container mr-widget-workflow">
      <grouped-test-reports-app
        v-if="mr.testResultsPath"
        class="js-reports-container"
        :endpoint="mr.testResultsPath"
      />

      <div class="mr-widget-section">
        <component :is="componentName" :mr="mr" :service="service" />

        <div class="mr-widget-info">
          <section v-if="shouldRenderCollaborationStatus" class="mr-info-list mr-links">
            <p>
              {{ s__('mrWidget|Allows commits from members who can merge to the target branch') }}
            </p>
          </section>

          <mr-widget-related-links
            v-if="shouldRenderRelatedLinks"
            :state="mr.state"
            :related-links="mr.relatedLinks"
          />

          <mr-widget-alert-message
            v-if="showMergePipelineForkWarning"
            type="warning"
            :help-path="mr.mergeRequestPipelinesHelpPath"
          >
            {{
              s__(
                'mrWidget|Fork merge requests do not create merge request pipelines which validate a post merge result',
              )
            }}
          </mr-widget-alert-message>

          <mr-widget-alert-message v-if="mr.mergeError" type="danger">
            {{ mergeError }}
          </mr-widget-alert-message>

          <source-branch-removal-status v-if="shouldRenderSourceBranchRemovalStatus" />
        </div>
      </div>
      <div v-if="shouldRenderMergeHelp" class="mr-widget-footer"><mr-widget-merge-help /></div>
    </div>
    <mr-widget-pipeline-container
      v-if="shouldRenderMergedPipeline"
      class="js-post-merge-pipeline mr-widget-workflow"
      :mr="mr"
      :is-post-merge="true"
    />
  </div>
  <loading v-else />
</template>
