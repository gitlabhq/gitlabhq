<script>
import { GlEmptyState, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { isEqual } from 'lodash';
import createFlash from '~/flash';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import { ANY_TRIGGER_AUTHOR, RAW_TEXT_WARNING, FILTER_TAG_IDENTIFIER } from '../../constants';
import PipelinesMixin from '../../mixins/pipelines_mixin';
import PipelinesService from '../../services/pipelines_service';
import { validateParams } from '../../utils';
import EmptyState from './empty_state.vue';
import NavigationControls from './nav_controls.vue';
import PipelinesFilteredSearch from './pipelines_filtered_search.vue';
import PipelinesTableComponent from './pipelines_table.vue';

export default {
  components: {
    EmptyState,
    GlEmptyState,
    GlIcon,
    GlLoadingIcon,
    NavigationTabs,
    NavigationControls,
    PipelinesFilteredSearch,
    PipelinesTableComponent,
    TablePagination,
  },
  mixins: [PipelinesMixin],
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
    pipelineScheduleUrl: {
      type: String,
      required: false,
      default: '',
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
    codeQualityPagePath: {
      type: String,
      required: false,
      default: null,
    },
    ciRunnerSettingsPath: {
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
      if (this.scope === this.$options.scopes.finished) {
        return s__('Pipelines|There are currently no finished pipelines.');
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
          name: __('Finished'),
          scope: scopes.finished,
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
    validatedParams() {
      return validateParams(this.params);
    },
  },
  created() {
    this.service = new PipelinesService(this.endpoint);
    this.requestData = { page: this.page, scope: this.scope, ...this.validatedParams };
  },
  methods: {
    onChangeTab(scope) {
      if (this.scope === scope) {
        return;
      }

      let params = {
        scope,
        page: '1',
      };

      params = this.onChangeWithFilter(params);

      this.updateContent(params);
    },
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
          createFlash({
            message: s__('Pipelines|Project cache successfully reset.'),
            type: 'notice',
          });
        })
        .catch(() => {
          this.isResetCacheButtonLoading = false;
          createFlash({
            message: s__('Pipelines|Something went wrong while cleaning runners cache.'),
          });
        });
    },
    resetRequestData() {
      this.requestData = { page: this.page, scope: this.scope };
    },
    filterPipelines(filters) {
      this.resetRequestData();

      filters.forEach((filter) => {
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
          createFlash({
            message: RAW_TEXT_WARNING,
            type: 'warning',
          });
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
      class="top-area scrolling-tabs-container inner-page-scroll-tabs gl-border-none"
    >
      <div class="fade-left"><gl-icon name="chevron-lg-left" :size="12" /></div>
      <div class="fade-right"><gl-icon name="chevron-lg-right" :size="12" /></div>

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
      v-if="stateToRender !== $options.stateMap.emptyState"
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
        :empty-state-svg-path="emptyStateSvgPath"
        :can-set-ci="canCreatePipeline"
        :code-quality-page-path="codeQualityPagePath"
        :ci-runner-settings-path="ciRunnerSettingsPath"
      />

      <gl-empty-state
        v-else-if="stateToRender === $options.stateMap.error"
        :svg-path="errorStateSvgPath"
        :title="
          s__(`Pipelines|There was an error fetching the pipelines.
        Try again in a few moments or contact your support team.`)
        "
      />

      <gl-empty-state
        v-else-if="stateToRender === $options.stateMap.emptyTab"
        :svg-path="noPipelinesSvgPath"
        :title="emptyTabMessage"
      />

      <div v-else-if="stateToRender === $options.stateMap.tableList">
        <pipelines-table-component
          :pipelines="state.pipelines"
          :pipeline-schedule-url="pipelineScheduleUrl"
          :update-graph-dropdown="updateGraphDropdown"
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
