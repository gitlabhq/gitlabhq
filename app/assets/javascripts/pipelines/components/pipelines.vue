<script>
import { isEqual } from 'lodash';
import { __, sprintf, s__ } from '../../locale';
import createFlash from '../../flash';
import PipelinesService from '../services/pipelines_service';
import pipelinesMixin from '../mixins/pipelines';
import TablePagination from '../../vue_shared/components/pagination/table_pagination.vue';
import NavigationTabs from '../../vue_shared/components/navigation_tabs.vue';
import NavigationControls from './nav_controls.vue';
import { getParameterByName } from '../../lib/utils/common_utils';
import CIPaginationMixin from '../../vue_shared/mixins/ci_pagination_api_mixin';
import PipelinesFilteredSearch from './pipelines_filtered_search.vue';
import { validateParams } from '../utils';
import { ANY_TRIGGER_AUTHOR, RAW_TEXT_WARNING, FILTER_TAG_IDENTIFIER } from '../constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';

export default {
  components: {
    TablePagination,
    NavigationTabs,
    NavigationControls,
    PipelinesFilteredSearch,
  },
  mixins: [pipelinesMixin, CIPaginationMixin, glFeatureFlagsMixin()],
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
    projectId: {
      type: String,
      required: true,
    },
    params: {
      type: Object,
      required: true,
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
    canFilterPipelines() {
      return this.glFeatures.filterPipelinesSearch;
    },
    validatedParams() {
      return validateParams(this.params);
    },
  },
  created() {
    this.service = new PipelinesService(this.endpoint);
    this.requestData = { page: this.page, scope: this.scope, ...this.validatedParams };
  },
  methods: {
    successCallback(resp) {
      // Because we are polling & the user is interacting verify if the response received
      // matches the last request made
      if (isEqual(resp.config.params, this.requestData)) {
        this.store.storeCount(resp.data.count);
        this.store.storePagination(resp.headers);
        this.setCommonData(resp.data.pipelines);
      }
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
    resetRequestData() {
      this.requestData = { page: this.page, scope: this.scope };
    },
    filterPipelines(filters) {
      this.resetRequestData();

      filters.forEach(filter => {
        // do not add Any for username query param, so we
        // can fetch all trigger authors
        if (
          filter.type &&
          filter.value.data !== ANY_TRIGGER_AUTHOR &&
          filter.type !== FILTER_TAG_IDENTIFIER
        ) {
          this.requestData[filter.type] = filter.value.data;
        }

        if (filter.type === FILTER_TAG_IDENTIFIER) {
          this.requestData.ref = filter.value.data;
        }

        if (!filter.type) {
          createFlash(RAW_TEXT_WARNING, 'warning');
        }
      });

      if (filters.length === 0) {
        this.resetRequestData();
      }

      this.updateContent(this.requestData);
    },
  },
};
</script>
<template>
  <div class="pipelines-container">
    <div
      v-if="shouldRenderTabs || shouldRenderButtons"
      class="top-area scrolling-tabs-container inner-page-scroll-tabs"
    >
      <div class="fade-left"><i class="fa fa-angle-left" aria-hidden="true"> </i></div>
      <div class="fade-right"><i class="fa fa-angle-right" aria-hidden="true"> </i></div>

      <navigation-tabs
        v-if="shouldRenderTabs"
        :tabs="tabs"
        scope="pipelines"
        @onChangeTab="onChangeTab"
      />

      <navigation-controls
        v-if="shouldRenderButtons"
        :new-pipeline-path="newPipelinePath"
        :reset-cache-path="resetCachePath"
        :ci-lint-path="ciLintPath"
        :is-reset-cache-button-loading="isResetCacheButtonLoading"
        @resetRunnersCache="handleResetRunnersCache"
      />
    </div>

    <pipelines-filtered-search
      v-if="canFilterPipelines"
      :project-id="projectId"
      :params="validatedParams"
      @filterPipelines="filterPipelines"
    />

    <div class="content-list pipelines">
      <gl-loading-icon
        v-if="stateToRender === $options.stateMap.loading"
        :label="s__('Pipelines|Loading Pipelines')"
        size="lg"
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
        :message="
          s__(`Pipelines|There was an error fetching the pipelines.
        Try again in a few moments or contact your support team.`)
        "
      />

      <svg-blank-state
        v-else-if="stateToRender === $options.stateMap.emptyTab"
        :svg-path="noPipelinesSvgPath"
        :message="emptyTabMessage"
      />

      <div v-else-if="stateToRender === $options.stateMap.tableList" class="table-holder">
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
