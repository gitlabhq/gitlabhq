<script>
import { GlSafeHtmlDirective } from '@gitlab/ui';
import { isEmpty } from 'lodash';
import MrWidgetApprovals from 'ee_else_ce/vue_merge_request_widget/components/approvals/approvals.vue';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';
import stateMaps from 'ee_else_ce/vue_merge_request_widget/stores/state_maps';
import createFlash from '~/flash';
import { secondsToMilliseconds } from '~/lib/utils/datetime_utility';
import notify from '~/lib/utils/notify';
import { sprintf, s__, __ } from '~/locale';
import Project from '~/pages/projects/project';
import SmartInterval from '~/smart_interval';
import { setFaviconOverlay } from '../lib/utils/favicon';
import GroupedAccessibilityReportsApp from '../reports/accessibility_report/grouped_accessibility_reports_app.vue';
import GroupedCodequalityReportsApp from '../reports/codequality_report/grouped_codequality_reports_app.vue';
import GroupedTestReportsApp from '../reports/grouped_test_report/grouped_test_reports_app.vue';
import Loading from './components/loading.vue';
import MrWidgetAlertMessage from './components/mr_widget_alert_message.vue';
import WidgetHeader from './components/mr_widget_header.vue';
import MrWidgetPipelineContainer from './components/mr_widget_pipeline_container.vue';
import WidgetRelatedLinks from './components/mr_widget_related_links.vue';
import WidgetSuggestPipeline from './components/mr_widget_suggest_pipeline.vue';
import SourceBranchRemovalStatus from './components/source_branch_removal_status.vue';
import ArchivedState from './components/states/mr_widget_archived.vue';
import MrWidgetAutoMergeEnabled from './components/states/mr_widget_auto_merge_enabled.vue';
import AutoMergeFailed from './components/states/mr_widget_auto_merge_failed.vue';
import CheckingState from './components/states/mr_widget_checking.vue';
import ClosedState from './components/states/mr_widget_closed.vue';
import ConflictsState from './components/states/mr_widget_conflicts.vue';
import FailedToMerge from './components/states/mr_widget_failed_to_merge.vue';
import MergedState from './components/states/mr_widget_merged.vue';
import MergingState from './components/states/mr_widget_merging.vue';
import MissingBranchState from './components/states/mr_widget_missing_branch.vue';
import NotAllowedState from './components/states/mr_widget_not_allowed.vue';
import PipelineBlockedState from './components/states/mr_widget_pipeline_blocked.vue';
import RebaseState from './components/states/mr_widget_rebase.vue';
import NothingToMergeState from './components/states/nothing_to_merge.vue';
import PipelineFailedState from './components/states/pipeline_failed.vue';
import ReadyToMergeState from './components/states/ready_to_merge.vue';
import UnresolvedDiscussionsState from './components/states/unresolved_discussions.vue';
import WorkInProgressState from './components/states/work_in_progress.vue';
// import ExtensionsContainer from './components/extensions/container';
import TerraformPlan from './components/terraform/mr_widget_terraform_container.vue';
import eventHub from './event_hub';
import mergeRequestQueryVariablesMixin from './mixins/merge_request_query_variables';
import getStateQuery from './queries/get_state.query.graphql';

export default {
  // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/25
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'MRWidget',
  directives: {
    SafeHtml: GlSafeHtmlDirective,
  },
  components: {
    Loading,
    // ExtensionsContainer,
    'mr-widget-header': WidgetHeader,
    'mr-widget-suggest-pipeline': WidgetSuggestPipeline,
    MrWidgetPipelineContainer,
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
    'sha-mismatch': ReadyToMergeState,
    'mr-widget-checking': CheckingState,
    'mr-widget-unresolved-discussions': UnresolvedDiscussionsState,
    'mr-widget-pipeline-blocked': PipelineBlockedState,
    'mr-widget-pipeline-failed': PipelineFailedState,
    MrWidgetAutoMergeEnabled,
    'mr-widget-auto-merge-failed': AutoMergeFailed,
    'mr-widget-rebase': RebaseState,
    SourceBranchRemovalStatus,
    GroupedCodequalityReportsApp,
    GroupedTestReportsApp,
    TerraformPlan,
    GroupedAccessibilityReportsApp,
    MrWidgetApprovals,
    SecurityReportsApp: () => import('~/vue_shared/security_reports/security_reports_app.vue'),
  },
  apollo: {
    state: {
      query: getStateQuery,
      manual: true,
      skip() {
        return !this.mr || !window.gon?.features?.mergeRequestWidgetGraphql;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      result({ data: { project } }) {
        if (project) {
          this.mr.setGraphqlData(project);
          this.loading = false;
        }
      },
    },
  },
  mixins: [mergeRequestQueryVariablesMixin],
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
      loading: true,
    };
  },
  computed: {
    isLoaded() {
      if (window.gon?.features?.mergeRequestWidgetGraphql) {
        return !this.loading;
      }

      return this.mr;
    },
    shouldRenderApprovals() {
      return this.mr.state !== 'nothingToMerge';
    },
    componentName() {
      return stateMaps.stateToComponentMap[this.mr.state];
    },
    hasPipelineMustSucceedConflict() {
      return !this.mr.hasCI && this.mr.onlyAllowMergeIfPipelineSucceeds;
    },
    shouldRenderPipelines() {
      return this.mr.hasCI || this.hasPipelineMustSucceedConflict;
    },
    shouldSuggestPipelines() {
      return (
        !this.mr.hasCI && this.mr.mergeRequestAddCiConfigPath && !this.mr.isDismissedSuggestPipeline
      );
    },
    shouldRenderCodeQuality() {
      return this.mr?.codeclimate?.head_path;
    },
    shouldRenderRelatedLinks() {
      return Boolean(this.mr.relatedLinks) && !this.mr.isNothingToMergeState;
    },
    shouldRenderSourceBranchRemovalStatus() {
      return (
        !this.mr.canRemoveSourceBranch &&
        this.mr.shouldRemoveSourceBranch &&
        !this.mr.isNothingToMergeState &&
        !this.mr.isMergedState
      );
    },
    shouldRenderCollaborationStatus() {
      return this.mr.allowCollaboration && this.mr.isOpen;
    },
    shouldRenderMergedPipeline() {
      return this.mr.state === 'merged' && !isEmpty(this.mr.mergePipeline);
    },
    showMergePipelineForkWarning() {
      return Boolean(
        this.mr.mergePipelinesEnabled && this.mr.sourceProjectId !== this.mr.targetProjectId,
      );
    },
    shouldRenderSecurityReport() {
      return Boolean(this.mr.pipeline.id);
    },
    mergeError() {
      let { mergeError } = this.mr;

      if (mergeError && mergeError.slice(-1) === '.') {
        mergeError = mergeError.slice(0, -1);
      }

      return sprintf(
        s__('mrWidget|%{mergeError}. Try again.'),
        {
          mergeError,
        },
        false,
      );
    },
    shouldShowAccessibilityReport() {
      return this.mr.accessibilityReportPath;
    },
    formattedHumanAccess() {
      return (this.mr.humanAccess || '').toLowerCase();
    },
    hasAlerts() {
      return this.mr.mergeError || this.showMergePipelineForkWarning;
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
    MRWidgetService.fetchInitialData()
      .then(({ data, headers }) => {
        this.startingPollInterval = Number(headers['POLL-INTERVAL']);
        this.initWidget(data);
      })
      .catch(() =>
        createFlash({
          message: __('Unable to load the merge request widget. Try reloading the page.'),
        }),
      );
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
        apiApprovalsPath: store.apiApprovalsPath,
        apiApprovePath: store.apiApprovePath,
        apiUnapprovePath: store.apiUnapprovePath,
      };
    },
    createService(store) {
      return new MRWidgetService(this.getServiceEndpoints(store));
    },
    checkStatus(cb, isRebased) {
      if (window.gon?.features?.mergeRequestWidgetGraphql) {
        this.$apollo.queries.state.refetch();
      }

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
        .catch(() =>
          createFlash({
            message: __('Something went wrong. Please try again.'),
          }),
        );
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
        startingInterval: this.startingPollInterval,
        maxInterval: this.startingPollInterval + secondsToMilliseconds(4 * 60),
        hiddenInterval: secondsToMilliseconds(6 * 60),
        incrementByFactorOf: 2,
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
        startingInterval: 30 * 1000,
        maxInterval: 240 * 1000,
        incrementByFactorOf: 4,
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
      createFlash({
        message: __(
          'Something went wrong while fetching the environments for this merge request. Please try again.',
        ),
      });
    },
    fetchActionsContent() {
      this.service
        .fetchMergeActionsContent()
        .then((res) => {
          if (res.data) {
            const el = document.createElement('div');
            el.innerHTML = res.data;
            document.body.appendChild(el);
            document.dispatchEvent(new CustomEvent('merged:UpdateActions'));
            Project.initRefSwitcher();
          }
        })
        .catch(() =>
          createFlash({
            message: __('Something went wrong. Please try again.'),
          }),
        );
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
      eventHub.$on('MRWidgetUpdateRequested', (cb) => {
        this.checkStatus(cb);
      });

      eventHub.$on('MRWidgetRebaseSuccess', (cb) => {
        this.checkStatus(cb, true);
      });

      // `params` should be an Array contains a Boolean, like `[true]`
      // Passing parameter as Boolean didn't work.
      eventHub.$on('SetBranchRemoveFlag', (params) => {
        [this.mr.isRemovingSourceBranch] = params;
      });

      eventHub.$on('FailedToMerge', (mergeError) => {
        this.mr.state = 'failedToMerge';
        this.mr.mergeError = mergeError;
      });

      eventHub.$on('UpdateWidgetData', (data) => {
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
    dismissSuggestPipelines() {
      this.mr.isDismissedSuggestPipeline = true;
    },
  },
};
</script>
<template>
  <div v-if="isLoaded" class="mr-state-widget gl-mt-3">
    <header class="gl-rounded-base gl-border-solid gl-border-1 gl-border-gray-100">
      <mr-widget-alert-message v-if="shouldRenderCollaborationStatus" type="info">
        {{ s__('mrWidget|Members who can merge are allowed to add commits.') }}
      </mr-widget-alert-message>
      <mr-widget-header :mr="mr" />
    </header>
    <mr-widget-suggest-pipeline
      v-if="shouldSuggestPipelines"
      data-testid="mr-suggest-pipeline"
      class="mr-widget-workflow"
      :pipeline-path="mr.mergeRequestAddCiConfigPath"
      :pipeline-svg-path="mr.pipelinesEmptySvgPath"
      :human-access="formattedHumanAccess"
      :user-callouts-path="mr.userCalloutsPath"
      :user-callout-feature-id="mr.suggestPipelineFeatureId"
      @dismiss="dismissSuggestPipelines"
    />
    <mr-widget-pipeline-container
      v-if="shouldRenderPipelines"
      class="mr-widget-workflow"
      :mr="mr"
    />
    <mr-widget-approvals
      v-if="shouldRenderApprovals"
      class="mr-widget-workflow"
      :mr="mr"
      :service="service"
    />
    <div class="mr-section-container mr-widget-workflow">
      <div v-if="hasAlerts" class="gl-overflow-hidden mr-widget-alert-container">
        <mr-widget-alert-message v-if="mr.mergeError" type="danger" dismissible>
          <span v-safe-html="mergeError"></span>
        </mr-widget-alert-message>
        <mr-widget-alert-message
          v-if="showMergePipelineForkWarning"
          type="warning"
          :help-path="mr.mergeRequestPipelinesHelpPath"
        >
          {{
            s__(
              'mrWidget|If the last pipeline ran in the fork project, it may be inaccurate. Before merge, we advise running a pipeline in this project.',
            )
          }}
          <template #link-content>
            {{ __('Learn more') }}
          </template>
        </mr-widget-alert-message>
      </div>
      <!-- <extensions-container :mr="mr" /> -->
      <grouped-codequality-reports-app
        v-if="shouldRenderCodeQuality"
        :base-path="mr.codeclimate.base_path"
        :head-path="mr.codeclimate.head_path"
        :head-blob-path="mr.headBlobPath"
        :base-blob-path="mr.baseBlobPath"
        :codequality-reports-path="mr.codequalityReportsPath"
        :codequality-help-path="mr.codequalityHelpPath"
      />

      <security-reports-app
        v-if="shouldRenderSecurityReport"
        :pipeline-id="mr.pipeline.id"
        :project-id="mr.sourceProjectId"
        :security-reports-docs-path="mr.securityReportsDocsPath"
        :target-project-full-path="mr.targetProjectFullPath"
        :mr-iid="mr.iid"
      />

      <grouped-test-reports-app
        v-if="mr.testResultsPath"
        class="js-reports-container"
        :endpoint="mr.testResultsPath"
        :head-blob-path="mr.headBlobPath"
        :pipeline-path="mr.pipeline.path"
      />

      <terraform-plan v-if="mr.terraformReportsPath" :endpoint="mr.terraformReportsPath" />

      <grouped-accessibility-reports-app
        v-if="shouldShowAccessibilityReport"
        :endpoint="mr.accessibilityReportPath"
      />

      <div class="mr-widget-section">
        <component :is="componentName" :mr="mr" :service="service" />

        <div class="mr-widget-info">
          <mr-widget-related-links
            v-if="shouldRenderRelatedLinks"
            :state="mr.state"
            :related-links="mr.relatedLinks"
          />

          <source-branch-removal-status v-if="shouldRenderSourceBranchRemovalStatus" />
        </div>
      </div>
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
