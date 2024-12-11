<script>
import { GlAlert, GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import getPipelineDetails from 'shared_queries/pipelines/get_pipeline_details.query.graphql';
import getUserCallouts from '~/graphql_shared/queries/get_user_callouts.query.graphql';
import { __, s__ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { DEFAULT, DRAW_FAILURE, LOAD_FAILURE } from '~/ci/pipeline_details/constants';
import getPipelineQuery from '~/ci/pipeline_details/header/graphql/queries/get_pipeline_header_data.query.graphql';
import { reportToSentry } from '~/ci/utils';
import DismissPipelineGraphCallout from './graphql/mutations/dismiss_pipeline_notification.graphql';
import {
  ACTION_FAILURE,
  IID_FAILURE,
  LAYER_VIEW,
  SKIP_RETRY_MODAL_KEY,
  STAGE_VIEW,
  VIEW_TYPE_KEY,
  POLL_INTERVAL,
} from './constants';
import PipelineGraph from './components/graph_component.vue';
import GraphViewSelector from './components/graph_view_selector.vue';
import {
  calculatePipelineLayersInfo,
  getQueryHeaders,
  serializeLoadErrors,
  toggleQueryPollingByVisibility,
  unwrapPipelineData,
} from './utils';

const featureName = 'pipeline_needs_hover_tip';
const enumFeatureName = featureName.toUpperCase();

export default {
  name: 'PipelineGraphWrapper',
  components: {
    GlAlert,
    GlLoadingIcon,
    GlSprintf,
    GraphViewSelector,
    LocalStorageSync,
    PipelineGraph,
  },
  inject: {
    graphqlResourceEtag: {
      default: '',
    },
    metricsPath: {
      default: '',
    },
    pipelineIid: {
      default: '',
    },
    pipelineProjectPath: {
      default: '',
    },
  },
  data() {
    return {
      alertType: null,
      callouts: [],
      computedPipelineInfo: null,
      currentViewType: STAGE_VIEW,
      canRefetchHeaderPipeline: false,
      pipeline: null,
      skipRetryModal: false,
      showAlert: false,
      showJobCountWarning: false,
      showLinks: false,
    };
  },
  errors: {
    [ACTION_FAILURE]: {
      text: __('An error occurred while performing this action.'),
      variant: 'danger',
    },
    [DRAW_FAILURE]: {
      text: __('An error occurred while drawing job relationship links.'),
      variant: 'danger',
    },
    [IID_FAILURE]: {
      text: __(
        'The data in this pipeline is too old to be rendered as a graph. Please check the Jobs tab to access historical data.',
      ),
      variant: 'info',
    },
    [LOAD_FAILURE]: {
      text: __('Currently unable to fetch data for this pipeline.'),
      variant: 'danger',
    },
    [DEFAULT]: {
      text: __('An unknown error occurred while loading this graph.'),
      variant: 'danger',
    },
  },
  apollo: {
    callouts: {
      query: getUserCallouts,
      update(data) {
        return data?.currentUser?.callouts?.nodes.map((callout) => callout.featureName) || [];
      },
      error(err) {
        reportToSentry(
          this.$options.name,
          `type: callout_load_failure, info: ${serializeLoadErrors(err)}`,
        );
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    headerPipeline: {
      query: getPipelineQuery,
      // this query is already being called in pipeline_header.vue, which shares the same cache as this component
      // the skip here is to prevent sending double network requests on page load
      skip() {
        return !this.canRefetchHeaderPipeline;
      },
      variables() {
        return {
          fullPath: this.pipelineProjectPath,
          iid: this.pipelineIid,
        };
      },
      update(data) {
        return data.project?.pipeline || {};
      },
      error() {
        this.reportFailure({ type: LOAD_FAILURE, skipSentry: true });
      },
    },
    pipeline: {
      context() {
        return getQueryHeaders(this.graphqlResourceEtag);
      },
      query: getPipelineDetails,
      pollInterval: POLL_INTERVAL,
      variables() {
        return {
          projectPath: this.pipelineProjectPath,
          iid: this.pipelineIid,
        };
      },
      skip() {
        return !(this.pipelineProjectPath && this.pipelineIid);
      },
      update(data) {
        /*
          This check prevents the pipeline from being overwritten
          when a poll times out and the data returned is empty.
          This can be removed once the timeout behavior is updated.
          See: https://gitlab.com/gitlab-org/gitlab/-/issues/323213.
        */

        if (!data?.project?.pipeline) {
          return this.pipeline;
        }

        return unwrapPipelineData(this.pipelineProjectPath, JSON.parse(JSON.stringify(data)));
      },
      error(err) {
        this.reportFailure({ type: LOAD_FAILURE, skipSentry: true });

        reportToSentry(this.$options.name, new Error(err));
      },
      result({ data, error }) {
        const stages = data?.project?.pipeline?.stages?.nodes || [];

        this.showJobCountWarning = stages.some((stage) => {
          return stage.groups.nodes.length >= 100;
        });
        /*
          If there is a successful load after a failure, clear
          the failure notification to avoid confusion.
        */
        if (!error && this.alertType === LOAD_FAILURE) {
          this.hideAlert();
        }
      },
    },
  },
  computed: {
    alert() {
      const { errors } = this.$options;

      return {
        text: errors[this.alertType]?.text ?? errors[DEFAULT].text,
        variant: errors[this.alertType]?.variant ?? errors[DEFAULT].variant,
      };
    },
    configPaths() {
      return {
        graphqlResourceEtag: this.graphqlResourceEtag,
        metricsPath: this.metricsPath,
      };
    },
    graphViewType() {
      /* This prevents reading view type off the localStorage value if it does not apply. */
      return this.showGraphViewSelector ? this.currentViewType : STAGE_VIEW;
    },
    hoverTipPreviouslyDismissed() {
      return this.callouts.includes(enumFeatureName);
    },
    showLoadingIcon() {
      /*
        Shows the icon only when the graph is empty, not when it is is
        being refetched, for instance, on action completion
      */
      return this.$apollo.queries.pipeline.loading && !this.pipeline;
    },
    showGraphViewSelector() {
      return this.pipeline?.usesNeeds;
    },
  },
  mounted() {
    if (!this.pipelineIid) {
      this.reportFailure({ type: IID_FAILURE, skipSentry: true });
    }
    toggleQueryPollingByVisibility(this.$apollo.queries.pipeline);
    this.skipRetryModal = Boolean(JSON.parse(localStorage.getItem(SKIP_RETRY_MODAL_KEY)));
  },
  methods: {
    getPipelineInfo() {
      if (this.currentViewType === LAYER_VIEW && !this.computedPipelineInfo) {
        this.computedPipelineInfo = calculatePipelineLayersInfo(
          this.pipeline,
          this.$options.name,
          this.metricsPath,
        );
      }

      return this.computedPipelineInfo;
    },
    handleTipDismissal() {
      try {
        this.$apollo.mutate({
          mutation: DismissPipelineGraphCallout,
          variables: {
            featureName,
          },
        });
      } catch (err) {
        reportToSentry(this.$options.name, `type: callout_dismiss_failure, info: ${err}`);
      }
    },
    hideAlert() {
      this.showAlert = false;
      this.alertType = null;
    },
    refreshPipelineGraph() {
      this.$apollo.queries.pipeline.refetch();

      // this will update the status in header_component since they share the same cache
      this.canRefetchHeaderPipeline = true;
      this.$apollo.queries.headerPipeline.refetch();
    },
    // eslint-disable-next-line @gitlab/require-i18n-strings
    reportFailure({ type, err = 'No error string passed.', skipSentry = false }) {
      this.showAlert = true;
      this.alertType = type;
      if (!skipSentry) {
        reportToSentry(this.$options.name, `type: ${type}, info: ${err}`);
      }
    },
    updateShowLinksState(val) {
      this.showLinks = val;
    },
    setSkipRetryModal() {
      this.skipRetryModal = true;
    },
    updateViewType(type) {
      this.currentViewType = type;
    },
  },
  i18n: {
    jobLimitWarning: {
      title: s__('Pipeline|Only the first 100 jobs per stage are displayed'),
      desc: s__('Pipeline|To see the remaining jobs, go to the %{boldStart}Jobs%{boldEnd} tab.'),
    },
  },
  viewTypeKey: VIEW_TYPE_KEY,
};
</script>
<template>
  <div>
    <gl-alert
      v-if="showAlert"
      :variant="alert.variant"
      data-testid="error-alert"
      @dismiss="hideAlert"
    >
      {{ alert.text }}
    </gl-alert>
    <gl-alert
      v-if="showJobCountWarning"
      variant="warning"
      :dismissible="false"
      :title="$options.i18n.jobLimitWarning.title"
      data-testid="job-count-warning"
    >
      <gl-sprintf :message="$options.i18n.jobLimitWarning.desc">
        <template #bold="{ content }">
          <b>{{ content }}</b>
        </template>
      </gl-sprintf>
    </gl-alert>
    <local-storage-sync
      :storage-key="$options.viewTypeKey"
      :value="currentViewType"
      as-string
      @input="updateViewType"
    >
      <graph-view-selector
        v-if="showGraphViewSelector"
        :type="graphViewType"
        :show-links="showLinks"
        :tip-previously-dismissed="hoverTipPreviouslyDismissed"
        @dismissHoverTip="handleTipDismissal"
        @updateViewType="updateViewType"
        @updateShowLinksState="updateShowLinksState"
      />
    </local-storage-sync>
    <gl-loading-icon v-if="showLoadingIcon" class="gl-mx-auto gl-my-4" size="lg" />
    <pipeline-graph
      v-if="pipeline"
      :config-paths="configPaths"
      :pipeline="pipeline"
      :computed-pipeline-info="getPipelineInfo()"
      :skip-retry-modal="skipRetryModal"
      :show-links="showLinks"
      :view-type="graphViewType"
      @error="reportFailure"
      @refreshPipelineGraph="refreshPipelineGraph"
      @setSkipRetryModal="setSkipRetryModal"
    />
  </div>
</template>
