<!-- eslint-disable vue/multi-word-component-names -->
<script>
import NO_PIPELINES_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-pipeline-md.svg?url';
import ERROR_STATE_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-job-failed-md.svg?url';
import { GlCollapsibleListbox, GlEmptyState, GlIcon, GlLoadingIcon } from '@gitlab/ui';
import { isEqual } from 'lodash';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { createAlert, VARIANT_INFO, VARIANT_WARNING } from '~/alert';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import Tracking from '~/tracking';
import {
  FILTER_TAG_IDENTIFIER,
  PIPELINE_ID_KEY,
  PIPELINE_IID_KEY,
  RAW_TEXT_WARNING,
  TRACKING_CATEGORIES,
} from '~/ci/constants';
import PipelinesTable from '~/ci/common/pipelines_table.vue';
import PipelinesMixin from '~/ci/pipeline_details/mixins/pipelines_mixin';
import { validateParams } from '~/ci/pipeline_details/utils';
import NavigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import { isLoggedIn } from '~/lib/utils/common_utils';
import setSortPreferenceMutation from '~/issues/list/queries/set_sort_preference.mutation.graphql';
import PipelinesService from './services/pipelines_service';
import { ANY_TRIGGER_AUTHOR } from './constants';
import NoCiEmptyState from './components/empty_state/no_ci_empty_state.vue';
import NavigationControls from './components/nav_controls.vue';
import PipelinesFilteredSearch from './components/pipelines_filtered_search.vue';

export default {
  components: {
    NoCiEmptyState,
    GlCollapsibleListbox,
    GlEmptyState,
    GlIcon,
    GlLoadingIcon,
    NavigationTabs,
    NavigationControls,
    PipelinesFilteredSearch,
    PipelinesTable,
    TablePagination,
    PipelineAccountVerificationAlert: () =>
      import('ee_component/vue_shared/components/pipeline_account_verification_alert.vue'),
  },
  mixins: [PipelinesMixin, Tracking.mixin()],
  props: {
    store: {
      type: Object,
      required: true,
    },
    endpoint: {
      type: String,
      required: true,
    },
    hasGitlabCi: {
      type: Boolean,
      required: true,
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
    params: {
      type: Object,
      required: true,
    },
    defaultVisibilityPipelineIdType: {
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
      visibilityPipelineIdType: this.defaultVisibilityPipelineIdType,
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
      return (this.newPipelinePath || this.resetCachePath) && this.shouldRenderTabs;
    },

    shouldRenderPagination() {
      return !this.isLoading && !this.hasError;
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
    selectedPipelineKeyOption() {
      return (
        this.$options.pipelineKeyOptions.find(
          (option) => this.visibilityPipelineIdType === option.value,
        ) || this.$options.pipelineKeyOptions[0]
      );
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

      this.track('click_filter_tabs', { label: TRACKING_CATEGORIES.tabs, property: scope });
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
          createAlert({
            message: s__('Pipelines|Project cache successfully reset.'),
            variant: VARIANT_INFO,
          });
        })
        .catch(() => {
          this.isResetCacheButtonLoading = false;
          createAlert({
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
          createAlert({
            message: RAW_TEXT_WARNING,
            variant: VARIANT_WARNING,
          });
        }
      });

      if (filters.length === 0) {
        this.resetRequestData();
      }

      this.updateContent({ ...this.requestData, page: '1' });
    },
    changeVisibilityPipelineIDType(idType) {
      this.visibilityPipelineIdType = idType;
      if (idType === PIPELINE_IID_KEY) {
        this.track('pipelines_display_options', {
          label: TRACKING_CATEGORIES.listbox,
          property: idType,
        });
      }

      if (isLoggedIn()) {
        this.saveVisibilityPipelineIDType(idType);
      }
    },
    saveVisibilityPipelineIDType(idType) {
      this.$apollo
        .mutate({
          mutation: setSortPreferenceMutation,
          variables: { input: { visibilityPipelineIdType: idType.toUpperCase() } },
        })
        .then(({ data }) => {
          if (data.userPreferencesUpdate.errors.length) {
            throw new Error(data.userPreferencesUpdate.errors);
          }
        })
        .catch((error) => {
          Sentry.captureException(error);
        });
    },
  },
  errorStateSvgPath: ERROR_STATE_SVG,
  noPipelinesSvgPath: NO_PIPELINES_SVG,
  pipelineKeyOptions: [
    {
      text: __('Show Pipeline ID'),
      label: __('Pipeline ID'),
      value: PIPELINE_ID_KEY,
    },
    {
      text: __('Show Pipeline IID'),
      label: __('Pipeline IID'),
      value: PIPELINE_IID_KEY,
    },
  ],
};
</script>
<template>
  <div class="pipelines-container gl-mt-2">
    <pipeline-account-verification-alert class="gl-mt-5" />
    <div
      v-if="shouldRenderTabs || shouldRenderButtons"
      class="top-area scrolling-tabs-container inner-page-scroll-tabs gl-border-none"
    >
      <div class="fade-left">
        <gl-icon name="chevron-lg-left" :size="12" />
      </div>
      <div class="fade-right">
        <gl-icon name="chevron-lg-right" :size="12" />
      </div>

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
        :is-reset-cache-button-loading="isResetCacheButtonLoading"
        @resetRunnersCache="handleResetRunnersCache"
      />
    </div>

    <div v-if="stateToRender !== $options.stateMap.emptyState" class="gl-flex">
      <div
        class="row-content-block gl-flex gl-max-w-full gl-flex-grow gl-flex-wrap gl-gap-4 gl-border-b-0 sm:gl-flex-nowrap"
      >
        <pipelines-filtered-search
          class="gl-flex gl-max-w-full gl-flex-grow"
          :params="validatedParams"
          @filterPipelines="filterPipelines"
        />
        <gl-collapsible-listbox
          v-model="visibilityPipelineIdType"
          class="gl-grow sm:gl-grow-0"
          toggle-class="gl-grow"
          :toggle-text="selectedPipelineKeyOption.text"
          :items="$options.pipelineKeyOptions"
          @select="changeVisibilityPipelineIDType"
        />
      </div>
    </div>

    <div class="content-list pipelines">
      <gl-loading-icon
        v-if="stateToRender === $options.stateMap.loading"
        :label="s__('Pipelines|Loading Pipelines')"
        size="lg"
        class="prepend-top-20"
      />

      <no-ci-empty-state
        v-else-if="stateToRender === $options.stateMap.emptyState"
        :empty-state-svg-path="$options.noPipelinesSvgPath"
      />

      <gl-empty-state
        v-else-if="stateToRender === $options.stateMap.error"
        :svg-path="$options.errorStateSvgPath"
        :title="s__('Pipelines|There was an error fetching the pipelines.')"
        :description="s__('Pipelines|Try again in a few moments or contact your support team.')"
      />

      <gl-empty-state
        v-else-if="stateToRender === $options.stateMap.emptyTab"
        :svg-path="$options.noPipelinesSvgPath"
        :title="emptyTabMessage"
      />

      <div v-else-if="stateToRender === $options.stateMap.tableList">
        <pipelines-table
          :pipelines="state.pipelines"
          :pipeline-id-type="selectedPipelineKeyOption.value"
          @cancel-pipeline="onCancelPipeline"
          @refresh-pipelines-table="onRefreshPipelinesTable"
          @retry-pipeline="onRetryPipeline"
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
