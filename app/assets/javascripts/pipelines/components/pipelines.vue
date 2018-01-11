<script>
  import _ from 'underscore';
  import PipelinesService from '../services/pipelines_service';
  import pipelinesMixin from '../mixins/pipelines';
  import tablePagination from '../../vue_shared/components/table_pagination.vue';
  import navigationTabs from '../../vue_shared/components/navigation_tabs.vue';
  import navigationControls from './nav_controls.vue';
  import {
    convertPermissionToBoolean,
    getParameterByName,
    parseQueryStringIntoObject,
  } from '../../lib/utils/common_utils';
  import CIPaginationMixin from '../../vue_shared/mixins/ci_pagination_api_mixin';

  export default {
    components: {
      tablePagination,
      navigationTabs,
      navigationControls,
    },
    mixins: [
      pipelinesMixin,
      CIPaginationMixin,
    ],
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
    },
    data() {
      const pipelinesData = document.querySelector('#pipelines-list-vue').dataset;

      return {
        endpoint: pipelinesData.endpoint,
        helpPagePath: pipelinesData.helpPagePath,
        emptyStateSvgPath: pipelinesData.emptyStateSvgPath,
        errorStateSvgPath: pipelinesData.errorStateSvgPath,
        autoDevopsPath: pipelinesData.helpAutoDevopsPath,
        newPipelinePath: pipelinesData.newPipelinePath,
        canCreatePipeline: pipelinesData.canCreatePipeline,
        hasCi: pipelinesData.hasCi,
        ciLintPath: pipelinesData.ciLintPath,
        resetCachePath: pipelinesData.resetCachePath,
        state: this.store.state,
        scope: getParameterByName('scope') || 'all',
        page: getParameterByName('page') || '1',
        requestData: {},
      };
    },
    computed: {
      canCreatePipelineParsed() {
        return convertPermissionToBoolean(this.canCreatePipeline);
      },

      /**
      * The empty state should only be rendered when the request is made to fetch all pipelines
      * and none is returned.
      *
      * @return {Boolean}
      */
      shouldRenderEmptyState() {
        return !this.isLoading &&
          !this.hasError &&
          this.hasMadeRequest &&
          !this.state.pipelines.length &&
          (this.scope === 'all' || this.scope === null);
      },
      /**
       * When a specific scope does not have pipelines we render a message.
       *
       * @return {Boolean}
       */
      shouldRenderNoPipelinesMessage() {
        return !this.isLoading &&
          !this.hasError &&
          !this.state.pipelines.length &&
          this.scope !== 'all' &&
          this.scope !== null;
      },

      shouldRenderTable() {
        return !this.hasError &&
          !this.isLoading && this.state.pipelines.length;
      },
      /**
      * Pagination should only be rendered when there is more than one page.
      *
      * @return {Boolean}
      */
      shouldRenderPagination() {
        return !this.isLoading &&
          this.state.pipelines.length &&
          this.state.pageInfo.total > this.state.pageInfo.perPage;
      },
      hasCiEnabled() {
        return this.hasCi !== undefined;
      },

      tabs() {
        const { count } = this.state;
        return [
          {
            name: 'All',
            scope: 'all',
            count: count.all,
            isActive: this.scope === 'all',
          },
          {
            name: 'Pending',
            scope: 'pending',
            count: count.pending,
            isActive: this.scope === 'pending',
          },
          {
            name: 'Running',
            scope: 'running',
            count: count.running,
            isActive: this.scope === 'running',
          },
          {
            name: 'Finished',
            scope: 'finished',
            count: count.finished,
            isActive: this.scope === 'finished',
          },
          {
            name: 'Branches',
            scope: 'branches',
            isActive: this.scope === 'branches',
          },
          {
            name: 'Tags',
            scope: 'tags',
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
        return resp.json().then((response) => {
          // Because we are polling & the user is interacting verify if the response received
          // matches the last request made
          if (_.isEqual(parseQueryStringIntoObject(resp.url.split('?')[1]), this.requestData)) {
            this.store.storeCount(response.count);
            this.store.storePagination(resp.headers);
            this.setCommonData(response.pipelines);
          }
        });
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
        return this.service.getPipelines(this.requestData)
          .then((response) => {
            this.isLoading = false;
            this.successCallback(response);

            // restart polling
            this.poll.restart({ data: this.requestData });
          })
          .catch(() => {
            this.isLoading = false;
            this.errorCallback();

            // restart polling
            this.poll.restart();
          });
      },
    },
  };
</script>
<template>
  <div class="pipelines-container">
    <div
      class="top-area scrolling-tabs-container inner-page-scroll-tabs"
      v-if="!shouldRenderEmptyState"
    >
      <div class="fade-left">
        <i
          class="fa fa-angle-left"
          aria-hidden="true">
        </i>
      </div>
      <div class="fade-right">
        <i
          class="fa fa-angle-right"
          aria-hidden="true">
        </i>
      </div>

      <navigation-tabs
        :tabs="tabs"
        @onChangeTab="onChangeTab"
        scope="pipelines"
      />

      <navigation-controls
        :new-pipeline-path="newPipelinePath"
        :has-ci-enabled="hasCiEnabled"
        :help-page-path="helpPagePath"
        :reset-cache-path="resetCachePath"
        :ci-lint-path="ciLintPath"
        :can-create-pipeline="canCreatePipelineParsed "
      />
    </div>

    <div class="content-list pipelines">

      <loading-icon
        label="Loading Pipelines"
        size="3"
        v-if="isLoading"
        class="prepend-top-20"
      />

      <empty-state
        v-if="shouldRenderEmptyState"
        :help-page-path="helpPagePath"
        :empty-state-svg-path="emptyStateSvgPath"
      />

      <error-state
        v-if="shouldRenderErrorState"
        :error-state-svg-path="errorStateSvgPath"
      />

      <div
        class="blank-state-row"
        v-if="shouldRenderNoPipelinesMessage"
      >
        <div class="blank-state-center">
          <h2 class="blank-state-title js-blank-state-title">No pipelines to show.</h2>
        </div>
      </div>

      <div
        class="table-holder"
        v-if="shouldRenderTable"
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
