<script>
  import PipelinesService from '../services/pipelines_service';
  import pipelinesMixin from '../mixins/pipelines';
  import tablePagination from '../../vue_shared/components/table_pagination.vue';
  import navigationTabs from './navigation_tabs.vue';
  import navigationControls from './nav_controls.vue';

  export default {
    props: {
      store: {
        type: Object,
        required: true,
      },
    },
    components: {
      tablePagination,
      navigationTabs,
      navigationControls,
    },
    mixins: [
      pipelinesMixin,
    ],
    data() {
      const pipelinesData = document.querySelector('#pipelines-list-vue').dataset;

      return {
        endpoint: pipelinesData.endpoint,
        cssClass: pipelinesData.cssClass,
        helpPagePath: pipelinesData.helpPagePath,
        autoDevopsPath: pipelinesData.helpAutoDevopsPath,
        newPipelinePath: pipelinesData.newPipelinePath,
        canCreatePipeline: pipelinesData.canCreatePipeline,
        allPath: pipelinesData.allPath,
        pendingPath: pipelinesData.pendingPath,
        runningPath: pipelinesData.runningPath,
        finishedPath: pipelinesData.finishedPath,
        branchesPath: pipelinesData.branchesPath,
        tagsPath: pipelinesData.tagsPath,
        hasCi: pipelinesData.hasCi,
        ciLintPath: pipelinesData.ciLintPath,
        state: this.store.state,
        apiScope: 'all',
        pagenum: 1,
      };
    },
    computed: {
      canCreatePipelineParsed() {
        return gl.utils.convertPermissionToBoolean(this.canCreatePipeline);
      },
      scope() {
        const scope = gl.utils.getParameterByName('scope');
        return scope === null ? 'all' : scope;
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
      paths() {
        return {
          allPath: this.allPath,
          pendingPath: this.pendingPath,
          finishedPath: this.finishedPath,
          runningPath: this.runningPath,
          branchesPath: this.branchesPath,
          tagsPath: this.tagsPath,
        };
      },
      pageParameter() {
        return gl.utils.getParameterByName('page') || this.pagenum;
      },
      scopeParameter() {
        return gl.utils.getParameterByName('scope') || this.apiScope;
      },
    },
    created() {
      this.service = new PipelinesService(this.endpoint);
      this.requestData = { page: this.pageParameter, scope: this.scopeParameter };
    },
    methods: {
      /**
       * Will change the page number and update the URL.
       *
       * @param  {Number} pageNumber desired page to go to.
       */
      change(pageNumber) {
        const param = gl.utils.setParamInURL('page', pageNumber);

        gl.utils.visitUrl(param);
        return param;
      },

      successCallback(resp) {
        return resp.json().then((response) => {
          this.store.storeCount(response.count);
          this.store.storePagination(resp.headers);
          this.setCommonData(response.pipelines);
        });
      },
    },
  };
</script>
<template>
  <div
    class="pipelines-container"
    :class="cssClass">
    <div
      class="top-area scrolling-tabs-container inner-page-scroll-tabs"
      v-if="!isLoading && !shouldRenderEmptyState">
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
        :scope="scope"
        :count="state.count"
        :paths="paths"
        />

      <navigation-controls
        :new-pipeline-path="newPipelinePath"
        :has-ci-enabled="hasCiEnabled"
        :help-page-path="helpPagePath"
        :ciLintPath="ciLintPath"
        :can-create-pipeline="canCreatePipelineParsed "
        />
    </div>

    <div class="content-list pipelines">

      <loading-icon
        label="Loading Pipelines"
        size="3"
        v-if="isLoading"
        />

      <empty-state
        v-if="shouldRenderEmptyState"
        :help-page-path="helpPagePath"
        />

      <error-state v-if="shouldRenderErrorState" />

      <div
        class="blank-state blank-state-no-icon"
        v-if="shouldRenderNoPipelinesMessage">
        <h2 class="blank-state-title js-blank-state-title">No pipelines to show.</h2>
      </div>

      <div
        class="table-holder"
        v-if="shouldRenderTable">

        <pipelines-table-component
          :pipelines="state.pipelines"
          :update-graph-dropdown="updateGraphDropdown"
          :auto-devops-help-path="autoDevopsPath"
          />
      </div>

      <table-pagination
        v-if="shouldRenderPagination"
        :change="change"
        :pageInfo="state.pageInfo"
        />
    </div>
  </div>
</template>
