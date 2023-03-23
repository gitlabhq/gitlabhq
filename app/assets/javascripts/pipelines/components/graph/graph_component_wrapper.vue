<script>
import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import getPipelineDetails from 'shared_queries/pipelines/get_pipeline_details.query.graphql';
import getUserCallouts from '~/graphql_shared/queries/get_user_callouts.query.graphql';
import { __ } from '~/locale';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { DEFAULT, DRAW_FAILURE, LOAD_FAILURE } from '../../constants';
import DismissPipelineGraphCallout from '../../graphql/mutations/dismiss_pipeline_notification.graphql';
import getPipelineQuery from '../../graphql/queries/get_pipeline_header_data.query.graphql';
import { reportToSentry, reportMessageToSentry } from '../../utils';
import {
  ACTION_FAILURE,
  IID_FAILURE,
  LAYER_VIEW,
  SKIP_RETRY_MODAL_KEY,
  STAGE_VIEW,
  VIEW_TYPE_KEY,
} from './constants';
import PipelineGraph from './graph_component.vue';
import GraphViewSelector from './graph_view_selector.vue';
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
    headerPipeline: {
      query: getPipelineQuery,
      // this query is already being called in header_component.vue, which shares the same cache as this component
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
      pollInterval: 10000,
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

        reportMessageToSentry(
          this.$options.name,
          `| type: ${LOAD_FAILURE} , info: ${JSON.stringify(err)}`,
          {
            graphViewType: this.graphViewType,
            graphqlResourceEtag: this.graphqlResourceEtag,
            metricsPath: this.metricsPath,
            projectPath: this.pipelineProjectPath,
            pipelineIid: this.pipelineIid,
          },
        );
      },
      result({ error }) {
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
  errorCaptured(err, _vm, info) {
    reportToSentry(this.$options.name, `error: ${err}, info: ${info}`);
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
  viewTypeKey: VIEW_TYPE_KEY,
};
</script>
<template>
  <div>
    <gl-alert v-if="showAlert" :variant="alert.variant" @dismiss="hideAlert">
      {{ alert.text }}
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
