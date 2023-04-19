<script>
import { isEmpty, clamp } from 'lodash';
import {
  registerExtension,
  registeredExtensions,
} from '~/vue_merge_request_widget/components/extensions';
import SafeHtml from '~/vue_shared/directives/safe_html';
import MrWidgetApprovals from 'ee_else_ce/vue_merge_request_widget/components/approvals/approvals.vue';
import MRWidgetService from 'ee_else_ce/vue_merge_request_widget/services/mr_widget_service';
import MRWidgetStore from 'ee_else_ce/vue_merge_request_widget/stores/mr_widget_store';
import { stateToComponentMap as classState } from 'ee_else_ce/vue_merge_request_widget/stores/state_maps';
import { createAlert } from '~/alert';
import { STATUS_CLOSED, STATUS_MERGED } from '~/issues/constants';
import notify from '~/lib/utils/notify';
import { sprintf, s__, __ } from '~/locale';
import SmartInterval from '~/smart_interval';
import { TYPENAME_MERGE_REQUEST } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { setFaviconOverlay } from '~/lib/utils/favicon';
import Loading from './components/loading.vue';
import MrWidgetAlertMessage from './components/mr_widget_alert_message.vue';
import MrWidgetPipelineContainer from './components/mr_widget_pipeline_container.vue';
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
import ShaMismatch from './components/states/sha_mismatch.vue';
import UnresolvedDiscussionsState from './components/states/unresolved_discussions.vue';
import WorkInProgressState from './components/states/work_in_progress.vue';
import ExtensionsContainer from './components/extensions/container';
import WidgetContainer from './components/widget/app.vue';
import {
  STATE_MACHINE,
  stateToComponentMap,
  STATE_QUERY_POLLING_INTERVAL_DEFAULT,
  STATE_QUERY_POLLING_INTERVAL_BACKOFF,
  FOUR_MINUTES_IN_MS,
} from './constants';
import eventHub from './event_hub';
import mergeRequestQueryVariablesMixin from './mixins/merge_request_query_variables';
import getStateQuery from './queries/get_state.query.graphql';
import getStateSubscription from './queries/get_state.subscription.graphql';
import terraformExtension from './extensions/terraform';
import accessibilityExtension from './extensions/accessibility';
import codeQualityExtension from './extensions/code_quality';
import testReportExtension from './extensions/test_report';
import ReportWidgetContainer from './components/report_widget_container.vue';
import MrWidgetReadyToMerge from './components/states/new_ready_to_merge.vue';

export default {
  // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/25
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'MRWidget',
  directives: {
    SafeHtml,
  },
  components: {
    Loading,
    ExtensionsContainer,
    WidgetContainer,
    MrWidgetSuggestPipeline: WidgetSuggestPipeline,
    MrWidgetPipelineContainer,
    MrWidgetAlertMessage,
    MrWidgetMerged: MergedState,
    MrWidgetClosed: ClosedState,
    MrWidgetMerging: MergingState,
    MrWidgetFailedToMerge: FailedToMerge,
    MrWidgetWip: WorkInProgressState,
    MrWidgetArchived: ArchivedState,
    MrWidgetConflicts: ConflictsState,
    MrWidgetNothingToMerge: NothingToMergeState,
    MrWidgetNotAllowed: NotAllowedState,
    MrWidgetMissingBranch: MissingBranchState,
    MrWidgetReadyToMerge,
    ShaMismatch,
    MrWidgetChecking: CheckingState,
    MrWidgetUnresolvedDiscussions: UnresolvedDiscussionsState,
    MrWidgetPipelineBlocked: PipelineBlockedState,
    MrWidgetPipelineFailed: PipelineFailedState,
    MrWidgetAutoMergeEnabled,
    MrWidgetAutoMergeFailed: AutoMergeFailed,
    MrWidgetRebase: RebaseState,
    SourceBranchRemovalStatus,
    MrWidgetApprovals,
    SecurityReportsApp: () => import('~/vue_shared/security_reports/security_reports_app.vue'),
    MergeChecksFailed: () => import('./components/states/merge_checks_failed.vue'),
    ReadyToMerge: ReadyToMergeState,
    ReportWidgetContainer,
  },
  apollo: {
    state: {
      query: getStateQuery,
      notifyOnNetworkStatusChange: true,
      manual: true,
      skip() {
        return !this.mr;
      },
      variables() {
        return this.mergeRequestQueryVariables;
      },
      pollInterval() {
        return this.pollInterval;
      },
      result(response) {
        if (!response.loading) {
          this.pollInterval = this.apolloStateQueryPollingInterval;

          if (response.data?.project) {
            this.mr.setGraphqlData(response.data.project);
            this.loading = false;
          }
        } else {
          this.checkStatus(undefined, undefined, false);
        }
      },
      subscribeToMore: {
        document() {
          return getStateSubscription;
        },
        skip() {
          return !this.mr?.id || this.loading || !window.gon?.features?.realtimeMrStatusChange;
        },
        variables() {
          return {
            issuableId: convertToGraphQLId(TYPENAME_MERGE_REQUEST, this.mr?.id),
          };
        },
        updateQuery(
          _,
          {
            subscriptionData: {
              data: { mergeRequestMergeStatusUpdated },
            },
          },
        ) {
          if (mergeRequestMergeStatusUpdated) {
            this.mr.setGraphqlSubscriptionData(mergeRequestMergeStatusUpdated);
          }
        },
      },
    },
  },
  mixins: [mergeRequestQueryVariablesMixin],
  provide: {
    expandDetailsTooltip: __('Expand merge details'),
    collapseDetailsTooltip: __('Collapse merge details'),
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
      machineState: store?.machineValue || STATE_MACHINE.definition.initial,
      loading: true,
      recomputeComponentName: 0,
      issuableId: false,
      startingPollInterval: STATE_QUERY_POLLING_INTERVAL_DEFAULT,
      pollInterval: STATE_QUERY_POLLING_INTERVAL_DEFAULT,
    };
  },
  computed: {
    apolloStateQueryMaxPollingInterval() {
      return this.startingPollInterval + FOUR_MINUTES_IN_MS;
    },
    apolloStateQueryPollingInterval() {
      if (this.startingPollInterval < 0) {
        return 0;
      }

      const unboundedInterval = STATE_QUERY_POLLING_INTERVAL_BACKOFF * this.pollInterval;

      return clamp(
        unboundedInterval,
        this.startingPollInterval,
        this.apolloStateQueryMaxPollingInterval,
      );
    },
    shouldRenderApprovals() {
      return this.mr.state !== 'nothingToMerge';
    },
    componentName() {
      return stateToComponentMap[this.machineState] || classState[this.mr.state];
    },
    hasPipelineMustSucceedConflict() {
      return !this.mr.hasCI && this.mr.onlyAllowMergeIfPipelineSucceeds;
    },
    shouldRenderPipelines() {
      return this.mr.hasCI || this.hasPipelineMustSucceedConflict;
    },
    shouldSuggestPipelines() {
      const { hasCI, mergeRequestAddCiConfigPath, isDismissedSuggestPipeline } = this.mr;

      return !hasCI && mergeRequestAddCiConfigPath && !isDismissedSuggestPipeline;
    },
    shouldRenderCodeQuality() {
      return this.mr?.codequalityReportsPath;
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
      return this.mr.state === STATUS_MERGED && !isEmpty(this.mr.mergePipeline);
    },
    showMergePipelineForkWarning() {
      return Boolean(
        this.mr.mergePipelinesEnabled && this.mr.sourceProjectId !== this.mr.targetProjectId,
      );
    },
    shouldRenderSecurityReport() {
      return Boolean(this.mr?.pipeline?.id);
    },
    shouldRenderTerraformPlans() {
      return Boolean(this.mr?.terraformReportsPath);
    },
    shouldRenderTestReport() {
      return Boolean(this.mr?.testResultsPath);
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
      return Boolean(this.mr?.accessibilityReportPath);
    },
    formattedHumanAccess() {
      return (this.mr.humanAccess || '').toLowerCase();
    },
    hasMergeError() {
      return this.mr.mergeError && this.state !== STATUS_CLOSED;
    },
    hasAlerts() {
      return this.hasMergeError || this.showMergePipelineForkWarning;
    },
    shouldShowSecurityExtension() {
      return window.gon?.features?.refactorSecurityExtension;
    },
    shouldShowMergeDetails() {
      if (this.mr.state === 'readyToMerge') return true;

      return !this.mr.mergeDetailsCollapsed;
    },
    hasExtensions() {
      return registeredExtensions.extensions.length;
    },
  },
  watch: {
    'mr.machineValue': {
      handler(newValue) {
        this.machineState = newValue;
      },
    },
    state(newVal, oldVal) {
      if (newVal !== oldVal && this.shouldRenderMergedPipeline) {
        // init polling
        this.initPostMergeDeploymentsPolling();
      }
    },
    shouldRenderTerraformPlans(newVal) {
      if (newVal) {
        this.registerTerraformPlans();
      }
    },
    shouldRenderCodeQuality(newVal) {
      if (newVal) {
        this.registerCodeQualityExtension();
      }
    },
    shouldShowAccessibilityReport(newVal) {
      if (newVal) {
        this.registerAccessibilityExtension();
      }
    },
    shouldRenderTestReport(newVal) {
      if (newVal) {
        this.registerTestReportExtension();
      }
    },
  },
  mounted() {
    MRWidgetService.fetchInitialData()
      .then(({ data, headers }) => {
        this.startingPollInterval =
          Number(headers['POLL-INTERVAL']) || STATE_QUERY_POLLING_INTERVAL_DEFAULT;
        this.initWidget(data);
      })
      .catch(() =>
        createAlert({
          message: __('Unable to load the merge request widget. Try reloading the page.'),
        }),
      );
  },
  beforeDestroy() {
    eventHub.$off('mr.discussion.updated', this.checkStatus);

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

      this.machineState = this.mr.machineValue;

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

      this.bindEventHubListeners();
      eventHub.$on('mr.discussion.updated', this.checkStatus);

      window.addEventListener('resize', () => {
        if (window.innerWidth >= 768) {
          this.mr.toggleMergeDetails(false);
        }
      });
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
    checkStatus(cb, isRebased, refetch = true) {
      if (refetch) {
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
          createAlert({
            message: __('Something went wrong. Please try again.'),
          }),
        );
    },
    setFaviconHelper() {
      if (this.mr.faviconOverlayPath) {
        return setFaviconOverlay(this.mr.faviconOverlayPath);
      }
      return Promise.resolve();
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
      createAlert({
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
            // eslint-disable-next-line no-unsanitized/property
            el.innerHTML = res.data;
            document.body.appendChild(el);
            document.dispatchEvent(new CustomEvent('merged:UpdateActions'));
          }
        })
        .catch(() =>
          createAlert({
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
      this.$apollo.queries.state.startPolling(this.pollInterval);
    },
    stopPolling() {
      this.$apollo.queries.state.stopPolling();
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

      eventHub.$on('FetchDeployments', () => {
        this.fetchPreMergeDeployments();
        if (this.shouldRenderMergedPipeline) {
          this.fetchPostMergeDeployments();
        }
      });
    },
    dismissSuggestPipelines() {
      this.mr.isDismissedSuggestPipeline = true;
    },
    registerTerraformPlans() {
      if (this.shouldRenderTerraformPlans) {
        registerExtension(terraformExtension);
      }
    },
    registerAccessibilityExtension() {
      if (this.shouldShowAccessibilityReport) {
        registerExtension(accessibilityExtension);
      }
    },
    registerCodeQualityExtension() {
      if (this.shouldRenderCodeQuality) {
        registerExtension(codeQualityExtension);
      }
    },
    registerTestReportExtension() {
      if (this.shouldRenderTestReport) {
        registerExtension(testReportExtension);
      }
    },
  },
};
</script>
<template>
  <div v-if="!loading" class="mr-state-widget gl-mt-3">
    <header
      v-if="shouldRenderCollaborationStatus"
      class="gl-rounded-base gl-border-solid gl-border-1 gl-border-gray-100 gl-overflow-hidden mr-widget-workflow gl-mt-0!"
    >
      <mr-widget-alert-message v-if="shouldRenderCollaborationStatus" type="info">
        {{ s__('mrWidget|Members who can merge are allowed to add commits.') }}
      </mr-widget-alert-message>
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
    <mr-widget-pipeline-container v-if="shouldRenderPipelines" :mr="mr" />
    <mr-widget-approvals v-if="shouldRenderApprovals" :mr="mr" :service="service" />
    <report-widget-container>
      <extensions-container v-if="hasExtensions" :mr="mr" />
      <widget-container v-if="mr && shouldShowSecurityExtension" :mr="mr" />
      <security-reports-app
        v-if="shouldRenderSecurityReport && !shouldShowSecurityExtension"
        :pipeline-id="mr.pipeline.id"
        :project-id="mr.sourceProjectId"
        :security-reports-docs-path="mr.securityReportsDocsPath"
        :target-project-full-path="mr.targetProjectFullPath"
        :mr-iid="mr.iid"
      />
    </report-widget-container>
    <div class="mr-section-container mr-widget-workflow">
      <div v-if="hasAlerts" class="gl-overflow-hidden mr-widget-alert-container">
        <mr-widget-alert-message
          v-if="hasMergeError"
          type="danger"
          dismissible
          data-testid="merge_error"
        >
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

      <div class="mr-widget-section" data-qa-selector="mr_widget_content">
        <component :is="componentName" :mr="mr" :service="service" />
        <ready-to-merge
          v-if="mr.commitsCount"
          v-show="shouldShowMergeDetails"
          :mr="mr"
          :service="service"
        />
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
