<script>
  import _ from 'underscore';
  import { __, sprintf, s__ } from '../../locale';
  import createFlash from '../../flash';
  import PipelinesService from '../services/pipelines_service';
  import pipelinesMixin from '../mixins/pipelines';
  import TablePagination from '../../vue_shared/components/table_pagination.vue';
  import NavigationTabs from '../../vue_shared/components/navigation_tabs.vue';
  import NavigationControls from './nav_controls.vue';
  import { getParameterByName } from '../../lib/utils/common_utils';
  import CIPaginationMixin from '../../vue_shared/mixins/ci_pagination_api_mixin';

  export default {
    components: {
      TablePagination,
      NavigationTabs,
      NavigationControls,
    },
    mixins: [pipelinesMixin, CIPaginationMixin],
    props: {
      store: {
        type: Object,
        required: true,
      },
      // Can be rendered in 3 different places, with some visual differences
      // Accepts root | child
      // `root` -> main view
      // `child` -> rendered inside MR or Commit View
      viewType: {
        type: String,
        required: false,
        default: 'root',
      },
      endpoint: {
        type: String,
        required: true,
      },
      helpPagePath: {
        type: String,
        required: true,
      },
      emptyStateSvgPath: {
        type: String,
        required: true,
      },
      errorStateSvgPath: {
        type: String,
        required: true,
      },
      noPipelinesSvgPath: {
        type: String,
        required: true,
      },
      autoDevopsPath: {
        type: String,
        required: true,
      },
      hasGitlabCi: {
        type: Boolean,
        required: true,
      },
      canCreatePipeline: {
        type: Boolean,
        required: true,
      },
      ciLintPath: {
        type: String,
        required: false,
        default: null,
      },
      resetCachePath: {
        type: String,
        required: false,
        default: null,
      },
      newPipelinePath: {
        type: String,
        required: false,
        default: null,
      },
    },
    data() {
      return {
        // Start with loading state to avoid a glitch when the empty state will be rendered
        isLoading: true,
        state: this.store.state,
        scope: getParameterByName('scope') || 'all',
        page: getParameterByName('page') || '1',
        requestData: {},
        isResetCacheButtonLoading: false,
      };
    },
    stateMap: {
      // with tabs
      loading: 'loading',
      tableList: 'tableList',
      error: 'error',
      emptyTab: 'emptyTab',

      // without tabs
      emptyState: 'emptyState',
    },
    scopes: {
      all: 'all',
      pending: 'pending',
      running: 'running',
      finished: 'finished',
      branches: 'branches',
      tags: 'tags',
    },
    computed: {
      /**
       * `hasGitlabCi` handles both internal and external CI.
       * The order on which  the checks are made in this method is
       * important to guarantee we handle all the corner cases.
       */
      stateToRender() {
        const { stateMap } = this.$options;

        if (this.isLoading) {
          return stateMap.loading;
        }

        if (this.hasError) {
          return stateMap.error;
        }

        if (this.state.pipelines.length) {
          return stateMap.tableList;
        }

        if ((this.scope !== 'all' && this.scope !== null) || this.hasGitlabCi) {
          return stateMap.emptyTab;
        }

        return stateMap.emptyState;
      },
      /**
       * Tabs are rendered in all states except empty state.
       * They are not rendered before the first request to avoid a flicker on first load.
       */
      shouldRenderTabs() {
        const { stateMap } = this.$options;
        return (
          this.hasMadeRequest &&
          [stateMap.loading, stateMap.tableList, stateMap.error, stateMap.emptyTab].includes(
            this.stateToRender,
          )
        );
      },

      shouldRenderButtons() {
        return (
          (this.newPipelinePath || this.resetCachePath || this.ciLintPath) && this.shouldRenderTabs
        );
      },

      shouldRenderPagination() {
        return (
          !this.isLoading &&
          this.state.pipelines.length &&
          this.state.pageInfo.total > this.state.pageInfo.perPage
        );
      },

      emptyTabMessage() {
        const { scopes } = this.$options;
        const possibleScopes = [scopes.pending, scopes.running, scopes.finished];

        if (possibleScopes.includes(this.scope)) {
          return sprintf(s__('Pipelines|There are currently no %{scope} pipelines.'), {
            scope: this.scope,
          });
        }

        return s__('Pipelines|There are currently no pipelines.');
      },

      tabs() {
        const { count } = this.state;
        const { scopes } = this.$options;

        return [
          {
            name: __('All'),
            scope: scopes.all,
            count: count.all,
            isActive: this.scope === 'all',
          },
          {
            name: __('Pending'),
            scope: scopes.pending,
            count: count.pending,
            isActive: this.scope === 'pending',
          },
          {
            name: __('Running'),
            scope: scopes.running,
            count: count.running,
            isActive: this.scope === 'running',
          },
          {
            name: __('Finished'),
            scope: scopes.finished,
            count: count.finished,
            isActive: this.scope === 'finished',
          },
          {
            name: __('Branches'),
            scope: scopes.branches,
            isActive: this.scope === 'branches',
          },
          {
            name: __('Tags'),
            scope: scopes.tags,
            isActive: this.scope === 'tags',
          },
        ];
      },
    },
    created() {
      this.service = new PipelinesService(this.endpoint);
      this.requestData = { page: this.page, scope: this.scope };
    },
    methods: {
      successCallback(resp) {
        // Because we are polling & the user is interacting verify if the response received
        // matches the last request made
        if (_.isEqual(resp.config.params, this.requestData)) {
          this.store.storeCount(resp.data.count);
          this.store.storePagination(resp.headers);
          this.setCommonData(resp.data.pipelines);
        }
      },
      /**
       * Handles URL and query parameter changes.
       * When the user uses the pagination or the tabs,
       *  - update URL
       *  - Make API request to the server with new parameters
       *  - Update the polling function
       *  - Update the internal state
       */
      updateContent(parameters) {
        this.updateInternalState(parameters);

        // fetch new data
        return this.service
          .getPipelines(this.requestData)
          .then(response => {
            this.isLoading = false;
            this.successCallback(response);

            // restart polling
            this.poll.restart({ data: this.requestData });
          })
          .catch(() => {
            this.isLoading = false;
            this.errorCallback();

            // restart polling
            this.poll.restart({ data: this.requestData });
          });
      },

      handleResetRunnersCache(endpoint) {
        this.isResetCacheButtonLoading = true;

        this.service
          .postAction(endpoint)
          .then(() => {
            this.isResetCacheButtonLoading = false;
            createFlash(s__('Pipelines|Project cache successfully reset.'), 'notice');
          })
          .catch(() => {
            this.isResetCacheButtonLoading = false;
            createFlash(s__('Pipelines|Something went wrong while cleaning runners cache.'));
          });
      },
    },
  };
</script>
<template>
  <div class="pipelines-container">
    <div
      class="top-area scrolling-tabs-container inner-page-scroll-tabs"
      v-if="shouldRenderTabs || shouldRenderButtons"
    >
      <div class="fade-left">
        <i
          class="fa fa-angle-left"
          aria-hidden="true"
        >
        </i>
      </div>
      <div class="fade-right">
        <i
          class="fa fa-angle-right"
          aria-hidden="true"
        >
        </i>
      </div>

      <navigation-tabs
        v-if="shouldRenderTabs"
        :tabs="tabs"
        @onChangeTab="onChangeTab"
        scope="pipelines"
      />

      <navigation-controls
        v-if="shouldRenderButtons"
        :new-pipeline-path="newPipelinePath"
        :reset-cache-path="resetCachePath"
        :ci-lint-path="ciLintPath"
        @resetRunnersCache="handleResetRunnersCache"
        :is-reset-cache-button-loading="isResetCacheButtonLoading"
      />
    </div>

    <div class="content-list pipelines">

      <loading-icon
        v-if="stateToRender === $options.stateMap.loading"
        :label="s__('Pipelines|Loading Pipelines')"
        size="3"
        class="prepend-top-20"
      />

      <empty-state
        v-else-if="stateToRender === $options.stateMap.emptyState"
        :help-page-path="helpPagePath"
        :empty-state-svg-path="emptyStateSvgPath"
        :can-set-ci="canCreatePipeline"
      />

      <svg-blank-state
        v-else-if="stateToRender === $options.stateMap.error"
        :svg-path="errorStateSvgPath"
        :message="s__(`Pipelines|There was an error fetching the pipelines.
        Try again in a few moments or contact your support team.`)"
      />

      <svg-blank-state
        v-else-if="stateToRender === $options.stateMap.emptyTab"
        :svg-path="noPipelinesSvgPath"
        :message="emptyTabMessage"
      />

      <div
        class="table-holder"
        v-else-if="stateToRender === $options.stateMap.tableList"
      >

        <pipelines-table-component
          :pipelines="state.pipelines"
          :update-graph-dropdown="updateGraphDropdown"
          :auto-devops-help-path="autoDevopsPath"
          :view-type="viewType"
        />
      </div>

      <table-pagination
        v-if="shouldRenderPagination"
        :change="onChangePage"
        :page-info="state.pageInfo"
      />
    </div>
  </div>
</template>
