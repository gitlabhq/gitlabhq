import Visibility from 'visibilityjs';
import PipelinesService from './services/pipelines_service';
import eventHub from './event_hub';
import pipelinesTableComponent from '../vue_shared/components/pipelines_table';
import tablePagination from '../vue_shared/components/table_pagination.vue';
import emptyState from './components/empty_state.vue';
import errorState from './components/error_state.vue';
import navigationTabs from './components/navigation_tabs';
import navigationControls from './components/nav_controls';
import loadingIcon from '../vue_shared/components/loading_icon.vue';
import Poll from '../lib/utils/poll';

export default {
  props: {
    store: {
      type: Object,
      required: true,
    },
  },

  components: {
    tablePagination,
    pipelinesTableComponent,
    emptyState,
    errorState,
    navigationTabs,
    navigationControls,
    loadingIcon,
  },

  data() {
    const pipelinesData = document.querySelector('#pipelines-list-vue').dataset;

    return {
      endpoint: pipelinesData.endpoint,
      cssClass: pipelinesData.cssClass,
      helpPagePath: pipelinesData.helpPagePath,
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
      isLoading: false,
      hasError: false,
      isMakingRequest: false,
      updateGraphDropdown: false,
      hasMadeRequest: false,
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

    shouldRenderErrorState() {
      return this.hasError && !this.isLoading;
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

    const poll = new Poll({
      resource: this.service,
      method: 'getPipelines',
      data: { page: this.pageParameter, scope: this.scopeParameter },
      successCallback: this.successCallback,
      errorCallback: this.errorCallback,
      notificationCallback: this.setIsMakingRequest,
    });

    if (!Visibility.hidden()) {
      this.isLoading = true;
      poll.makeRequest();
    } else {
      // If tab is not visible we need to make the first request so we don't show the empty
      // state without knowing if there are any pipelines
      this.fetchPipelines();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        poll.restart();
      } else {
        poll.stop();
      }
    });

    eventHub.$on('refreshPipelines', this.fetchPipelines);
  },

  beforeDestroyed() {
    eventHub.$off('refreshPipelines');
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

    fetchPipelines() {
      if (!this.isMakingRequest) {
        this.isLoading = true;

        this.service.getPipelines({ scope: this.scopeParameter, page: this.pageParameter })
          .then(response => this.successCallback(response))
          .catch(() => this.errorCallback());
      }
    },

    successCallback(resp) {
      const response = {
        headers: resp.headers,
        body: resp.json(),
      };

      this.store.storeCount(response.body.count);
      this.store.storePipelines(response.body.pipelines);
      this.store.storePagination(response.headers);

      this.isLoading = false;
      this.updateGraphDropdown = true;
      this.hasMadeRequest = true;
    },

    errorCallback() {
      this.hasError = true;
      this.isLoading = false;
      this.updateGraphDropdown = false;
    },

    setIsMakingRequest(isMakingRequest) {
      this.isMakingRequest = isMakingRequest;

      if (isMakingRequest) {
        this.updateGraphDropdown = false;
      }
    },
  },

  template: `
    <div :class="cssClass">

      <div
        class="top-area scrolling-tabs-container inner-page-scroll-tabs"
        v-if="!isLoading && !shouldRenderEmptyState">
        <div class="fade-left">
          <i class="fa fa-angle-left" aria-hidden="true"></i>
        </div>
        <div class="fade-right">
          <i class="fa fa-angle-right" aria-hidden="true"></i>
        </div>
        <navigation-tabs
          :scope="scope"
          :count="state.count"
          :paths="paths" />

        <navigation-controls
          :new-pipeline-path="newPipelinePath"
          :has-ci-enabled="hasCiEnabled"
          :help-page-path="helpPagePath"
          :ciLintPath="ciLintPath"
          :can-create-pipeline="canCreatePipelineParsed " />
      </div>

      <div class="content-list pipelines">

        <loading-icon
          label="Loading Pipelines"
          size="3"
          v-if="isLoading"
          />

        <empty-state
          v-if="shouldRenderEmptyState"
          :help-page-path="helpPagePath" />

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
            :service="service"
            :update-graph-dropdown="updateGraphDropdown"
            />
        </div>

        <table-pagination
          v-if="shouldRenderPagination"
          :pagenum="pagenum"
          :change="change"
          :count="state.count.all"
          :pageInfo="state.pageInfo"
          />
      </div>
    </div>
  `,
};
