<script>
import { isEmpty, clamp } from 'lodash';
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
import MrWidgetMigrateJenkins from './components/mr_widget_migrate_jenkins.vue';
import SourceBranchRemovalStatus from './components/source_branch_removal_status.vue';
import ArchivedState from './components/states/mr_widget_archived.vue';
import MrWidgetAutoMergeEnabled from './components/states/mr_widget_auto_merge_enabled.vue';
import AutoMergeFailed from './components/states/mr_widget_auto_merge_failed.vue';
import CheckingState from './components/states/mr_widget_checking.vue';
import PreparingState from './components/states/mr_widget_preparing.vue';
import ClosedState from './components/states/mr_widget_closed.vue';
import FailedToMerge from './components/states/mr_widget_failed_to_merge.vue';
import MergedState from './components/states/mr_widget_merged.vue';
import MergingState from './components/states/mr_widget_merging.vue';
import MissingBranchState from './components/states/mr_widget_missing_branch.vue';
import NothingToMergeState from './components/states/nothing_to_merge.vue';
import ReadyToMergeState from './components/states/ready_to_merge.vue';
import ShaMismatch from './components/states/sha_mismatch.vue';
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
import MrWidgetReadyToMerge from './components/states/new_ready_to_merge.vue';
import MergeChecks from './components/merge_checks.vue';

export default {
  // False positive i18n lint: https://gitlab.com/gitlab-org/frontend/eslint-plugin-i18n/issues/25
  // eslint-disable-next-line @gitlab/require-i18n-strings
  name: 'MRWidget',
  directives: {
    SafeHtml,
  },
  components: {
    Loading,
    WidgetContainer,
    MrWidgetSuggestPipeline: WidgetSuggestPipeline,
    MrWidgetMigrateJenkins,
    MrWidgetPipelineContainer,
    MrWidgetAlertMessage,
    MrWidgetMerged: MergedState,
    MrWidgetClosed: ClosedState,
    MrWidgetMerging: MergingState,
    MrWidgetFailedToMerge: FailedToMerge,
    MrWidgetArchived: ArchivedState,
    MrWidgetNothingToMerge: NothingToMergeState,
    MrWidgetMissingBranch: MissingBranchState,
    MrWidgetReadyToMerge,
    ShaMismatch,
    MrWidgetChecking: CheckingState,
    MrWidgetPreparing: PreparingState,
    MrWidgetAutoMergeEnabled,
    MrWidgetAutoMergeFailed: AutoMergeFailed,
    SourceBranchRemovalStatus,
    MrWidgetApprovals,
    ReadyToMerge: ReadyToMergeState,
    MergeChecks,
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
        // 7 is the value for when the network status is ready
        if (response.networkStatus !== 7) return;

        this.pollInterval = this.apolloStateQueryPollingInterval;

        if (response.data?.project) {
          this.mr.setGraphqlData(response.data.project);
          this.loading = false;
        }

        this.checkStatus(undefined, undefined, false);
      },
      error() {
        this.pollInterval = null;
      },
      subscribeToMore: {
        document() {
          return getStateSubscription;
        },
        skip() {
          return !this.mr?.id || this.loading;
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
      return !['preparing', 'nothingToMerge'].includes(this.mr.state);
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
    showRenderMigrateFromJenkins() {
      const { hasCI, isDismissedJenkinsMigration, ciIntegrationJenkins } = this.mr;

      return hasCI && !isDismissedJenkinsMigration && ciIntegrationJenkins;
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
    formattedHumanAccess() {
      return (this.mr.humanAccess || '').toLowerCase();
    },
    hasMergeError() {
      return this.mr.mergeError && this.state !== STATUS_CLOSED;
    },
    hasAlerts() {
      return this.hasMergeError || this.showMergePipelineForkWarning;
    },
    mergeBlockedComponentVisible() {
      return !(
        [
          'checking',
          'preparing',
          'nothingToMerge',
          'archived',
          'missingBranch',
          'merged',
          'closed',
          'merging',
          'shaMismatch',
        ].includes(this.mr.state) || this.mr.machineValue === 'MERGING'
      );
    },
    autoMergeEnabled() {
      return this.mr.autoMergeEnabled;
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
    'mr.ciStatus': {
      handler(newValue) {
        if (!newValue || this.loading) return;

        this.handleNotification();
      },
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
    this.unbindEventListeners();

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
          if (!Object.keys(data).length) return;

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
    handleNotification() {
      const { pipeline } = this.mr;

      if (!pipeline || !Object.keys(pipeline).length) return;

      const { label } = pipeline.details.status;
      const title = sprintf(__('Pipeline %{label}'), { label });
      const message = sprintf(__('Pipeline %{label} for "%{dataTitle}"'), {
        dataTitle: this.mr.title,
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
    checkRebasedStatus(cb) {
      this.checkStatus(cb, true);
    },
    setIsRemovingSourceBranch([value]) {
      this.mr.isRemovingSourceBranch = value;
    },
    setMergeError(mergeError) {
      this.mr.state = 'failedToMerge';
      this.mr.mergeError = mergeError;
    },
    setMrData(data) {
      this.mr.setData(data);
    },
    onFetchDeployments() {
      this.fetchPreMergeDeployments();
      if (this.shouldRenderMergedPipeline) {
        this.fetchPostMergeDeployments();
      }
    },
    bindEventHubListeners() {
      eventHub.$on('MRWidgetUpdateRequested', this.checkStatus);
      eventHub.$on('MRWidgetRebaseSuccess', this.checkRebasedStatus);
      eventHub.$on('SetBranchRemoveFlag', this.setIsRemovingSourceBranch);
      eventHub.$on('FailedToMerge', this.setMergeError);
      eventHub.$on('UpdateWidgetData', this.setMrData);
      eventHub.$on('FetchActionsContent', this.fetchActionsContent);
      eventHub.$on('EnablePolling', this.resumePolling);
      eventHub.$on('DisablePolling', this.stopPolling);
      eventHub.$on('FetchDeployments', this.onFetchDeployments);
    },
    unbindEventListeners() {
      eventHub.$off('MRWidgetUpdateRequested', this.checkStatus);
      eventHub.$off('MRWidgetRebaseSuccess', this.checkRebasedStatus);
      eventHub.$off('SetBranchRemoveFlag', this.setIsRemovingSourceBranch);
      eventHub.$off('FailedToMerge', this.setMergeError);
      eventHub.$off('UpdateWidgetData', this.setMrData);
      eventHub.$off('FetchActionsContent', this.fetchActionsContent);
      eventHub.$off('EnablePolling', this.resumePolling);
      eventHub.$off('DisablePolling', this.stopPolling);
      eventHub.$off('FetchDeployments', this.onFetchDeployments);
      eventHub.$off('mr.discussion.updated', this.checkStatus);
    },
    dismissSuggestPipelines() {
      this.mr.isDismissedSuggestPipeline = true;
    },
    dismissMigrateFromJenkins() {
      this.mr.isDismissedJenkinsMigration = true;
    },
  },
};
</script>
<template>
  <div v-if="!loading" id="widget-state" class="mr-state-widget gl-mt-5">
    <header v-if="shouldRenderCollaborationStatus" class="mr-section-container gl-overflow-hidden">
      <mr-widget-alert-message type="info">
        {{ s__('mrWidget|Members who can merge are allowed to add commits.') }}
      </mr-widget-alert-message>
    </header>
    <mr-widget-suggest-pipeline
      v-if="shouldSuggestPipelines"
      :pipeline-path="mr.mergeRequestAddCiConfigPath"
      :pipeline-svg-path="mr.pipelinesEmptySvgPath"
      :human-access="formattedHumanAccess"
      :user-callouts-path="mr.userCalloutsPath"
      :user-callout-feature-id="mr.suggestPipelineFeatureId"
      @dismiss="dismissSuggestPipelines"
    />
    <mr-widget-migrate-jenkins
      v-if="showRenderMigrateFromJenkins"
      class="mr-widget-workflow"
      :human-access="formattedHumanAccess"
      :path="mr.userCalloutsPath"
      :feature-id="mr.migrateJenkinsFeatureId"
      @dismiss="dismissMigrateFromJenkins"
    />
    <mr-widget-pipeline-container
      v-if="shouldRenderPipelines"
      :mr="mr"
      data-testid="pipeline-container"
    />
    <mr-widget-approvals v-if="shouldRenderApprovals" :mr="mr" :service="service" />
    <widget-container :mr="mr" />
    <div class="mr-section-container">
      <template v-if="hasAlerts">
        <mr-widget-alert-message
          v-if="hasMergeError"
          type="danger"
          dismissible
          data-testid="merge-error"
          class="mr-widget-section gl-rounded-b-none gl-border-b-section"
        >
          <span v-safe-html="mergeError"></span>
        </mr-widget-alert-message>
        <mr-widget-alert-message
          v-if="showMergePipelineForkWarning"
          type="warning"
          :help-path="mr.mergeRequestPipelinesHelpPath"
          class="mr-widget-section gl-rounded-b-none gl-border-b-section"
          data-testid="merge-pipeline-fork-warning"
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
      </template>

      <div class="mr-widget-section" data-testid="mr-widget-content">
        <template v-if="mergeBlockedComponentVisible">
          <mr-widget-auto-merge-enabled
            v-if="autoMergeEnabled"
            :mr="mr"
            :service="service"
            class="gl-border-b gl-border-b-section"
          />
          <merge-checks :mr="mr" :service="service" />
        </template>
        <component :is="componentName" v-else :mr="mr" :service="service" />
        <ready-to-merge v-if="mr.commitsCount" :mr="mr" :service="service" />
      </div>
    </div>
    <mr-widget-pipeline-container
      v-if="shouldRenderMergedPipeline"
      class="js-post-merge-pipeline"
      :mr="mr"
      is-post-merge
      data-testid="merged-pipeline-container"
    />
  </div>
  <loading v-else />
</template>
